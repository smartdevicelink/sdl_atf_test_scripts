---------------------------------------------------------------------------------------------------
-- Script verifies PTU sequence in protected mode
-- Supported PROPRIETARY, EXTERNAL_PROPRIETARY and HTTP flows
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Security/SSLHandshakeFlow/common")
local utils = require("user_modules/utils")
local SDL = require('SDL')
local atf_logger = require("atf_logger")
local constants = require('protocol_handler/ford_protocol_constants')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2
constants.FRAME_SIZE["P2"] = 1400

--[[ Local Variables ]]
local policyMode = SDL.buildOptions.extendedPolicy

local policyModes = {
  P  = "PROPRIETARY",
  EP = "EXTERNAL_PROPRIETARY",
  H  = "HTTP"
}

--[[ Local Functions ]]
local function log(...)
  local str = "[" .. atf_logger.formated_time(true) .. "]"
  for i, p in pairs({...}) do
    local delimiter = "\t"
    if i == 1 then delimiter = " " end
    str = str .. delimiter .. p
  end
  utils.cprint(35, str)
end

local function startServiceProtectedACK()
  local serviceId = 7
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
  common.getMobileSession():ExpectHandshakeMessage()
end

local function getPTS(pBinData)
  local pts = pBinData
  if policyMode == policyModes.P then
    pts = common.json.decode(pBinData).HTTPRequest.body
  end
  return common.json.decode(pts)
end

local function getPTUFromPTS(pPTSTable)
  local ptu = utils.cloneTable(pPTSTable)
  if next(ptu) ~= nil then
    local keysToRemove = { "consumer_friendly_messages", "device_data", "module_meta", "usage_and_error_counts", "vehicle_data" }
    for _, k in pairs(keysToRemove) do ptu.policy_table[k] = nil end
    ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null
    ptu.policy_table.module_config.preloaded_pt = nil
    ptu.policy_table.module_config.preloaded_date = nil
  end
  return ptu
end

local function regExpFinishedMsg()
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
  :Do(function() log("SDL->HMI:  N:", "SDL.OnStatusUpdate(UP_TO_DATE)") end)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  :Do(function() log("SDL->HMI:  N:", "VehicleInfo.GetVehicleData(odometer)") end)
end

local function policyTableUpdateProprietary()
  log("HMI->SDL: RQ:", "SDL.GetPolicyConfigurationData")
  local cid = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
    { policyType = "module_config", property = "endpoints" })
  common.getHMIConnection():ExpectResponse(cid)
  :Do(function()
      log("SDL->HMI: RS:", "SDL.GetPolicyConfigurationData")
      common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = common.sdl.getPTSFilePath() })
      common.getMobileSession():ExpectEncryptedNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, d1)
          log("SDL->MOB:  N:", "OnSystemRequest (encrypted)")
          local ptuFileName = os.tmpname()
          local ptsTable = getPTS(d1.binaryData)
          local ptuTable = getPTUFromPTS(ptsTable)
          utils.tableToJsonFile(ptuTable, ptuFileName)
          common.getHMIConnection():ExpectRequest("BasicCommunication.SystemRequest")
          :Do(function(_, d2)
              log("SDL->HMI: RQ:", "BC.SystemRequest")
              log("HMI->SDL: RS:", "BC.SystemRequest")
              common.getHMIConnection():SendResponse(d2.id, d2.method, "SUCCESS", { })
              log("HMI->SDL:  N:", "SDL.OnReceivedPolicyUpdate")
              common.getHMIConnection():SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = d2.params.fileName })
              regExpFinishedMsg()
            end)
          log("MOB->SDL: RQ:", "SystemRequest (encrypted)")
          local cid2 = common.getMobileSession():SendEncryptedRPC("SystemRequest", { requestType = "PROPRIETARY" }, ptuFileName)
          common.getMobileSession():ExpectEncryptedResponse(cid2, { success = true, resultCode = "SUCCESS" })
          :Do(function() log("SDL->MOB: RS:", "SystemRequest (encrypted)") end)
          :Do(function() os.remove(ptuFileName) end)
        end)
    end)
end

local function policyTableUpdateHttp()
  local ptuFileName = os.tmpname()
  local ptsTable = common.sdl.getPTS()
  local ptuTable = getPTUFromPTS(ptsTable)
  utils.tableToJsonFile(ptuTable, ptuFileName)
  regExpFinishedMsg()
  log("MOB->SDL: RQ:", "SystemRequest (encrypted)")
  local cid = common.getMobileSession():SendEncryptedRPC("SystemRequest",
    { requestType = "HTTP", fileName = "PolicyTableUpdate" }, ptuFileName)
  common.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function() log("SDL->MOB: RS:", "SystemRequest (encrypted)") end)
  :Do(function() os.remove(ptuFileName) end)
end

local function policyTableUpdate()
  if policyMode == policyModes.P or policyMode == policyModes.EP then
    policyTableUpdateProprietary()
  elseif policyMode == policyModes.H then
    policyTableUpdateHttp()
  end
end

local function checkPTUStatus()
  local cid = common.getHMIConnection():SendRequest("SDL.GetStatusUpdate")
  log("HMI->SDL: RQ: SDL.GetStatusUpdate")
  common.getHMIConnection():ExpectResponse(cid, { result = { status = "UP_TO_DATE" }})
  :Do(function(_, d)
      log("HMI->SDL: RS: SDL.GetStatusUpdate", tostring(d.result.status))
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("Switch RPC Service to Protected mode ACK", startServiceProtectedACK)
runner.Step("PTU in secure mode SUCCESS", policyTableUpdate)
runner.Step("Check Status", checkPTUStatus)

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
