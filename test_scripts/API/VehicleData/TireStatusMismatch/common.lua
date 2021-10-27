---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")

--[[ General configuration parameters ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local m = {}

--[[ Common Proxy Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.start = actions.start
m.registerApp = actions.app.register
m.registerAppWOPTU = actions.app.registerNoPTU
m.activateApp = actions.app.activate
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.hmi.getConnection
m.policyTableUpdate = actions.policyTableUpdate
m.cloneTable = utils.cloneTable
m.spairs = utils.spairs
m.isTableEqual = utils.isTableEqual
m.tableToString = utils.tableToString

--[[ Common Variables ]]
m.tirePressureParams = {
  "pressureTelltale", "leftFront", "rightFront", "leftRear", "rightRear", "innerLeftRear", "innerRightRear"
}

--[[ Common Functions ]]
function m.ptUpdate(pTbl)
  local grp = pTbl.policy_table.functional_groupings["Location-1"]
  grp.user_consent_prompt = nil
  for _, rpc in pairs(grp.rpcs) do
    table.insert(rpc.parameters, "tirePressure")
  end
end

function m.getDefaultValue(pParam)
  if pParam == "pressureTelltale" then return "NOT_USED" end
  return {
    status = "UNKNOWN"
  }
end

function m.getTirePressureDefaultValue()
  local out = {}
  for _, p in pairs(m.tirePressureParams) do
    out[p] = m.getDefaultValue(p)
  end
  return out
end

function m.getNonDefaultValue(pParam)
  if pParam == "pressureTelltale" then return "ON" end
  return {
    status = "NORMAL",
    tpms = "TRAIN",
    pressure = 1.1
  }
end

function m.getTirePressureNonDefaultValue()
  local out = {}
  for _, p in pairs(m.tirePressureParams) do
    out[p] = m.getNonDefaultValue(p)
  end
  return out
end

function m.sendGetVehicleData(pHmiResponse, pAppResponse)
  local cid = actions.getMobileSession():SendRPC("GetVehicleData", { tirePressure = true })
  actions.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { tirePressure = true })
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { tirePressure = pHmiResponse })
    end)
  actions.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", tirePressure = pAppResponse })
end

function m.subscribeVehicleData(pAppId, isRequestOnHMIExpected)
  if pAppId == nil then pAppId = 1 end
  if isRequestOnHMIExpected == nil then isRequestOnHMIExpected = true end
  local tirePressureResponseData = {
    dataType = "VEHICLEDATA_TIREPRESSURE",
    resultCode = "SUCCESS"
  }
  local cid = actions.getMobileSession(pAppId):SendRPC("SubscribeVehicleData", { tirePressure = true })
  if isRequestOnHMIExpected == true then
    actions.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { tirePressure = true })
    :Do(function(_,data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { tirePressure = tirePressureResponseData })
    end)
  else
    actions.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { tirePressure = true }):Times(0)
  end
  actions.getMobileSession(pAppId):ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", tirePressure = tirePressureResponseData })
end

return m
