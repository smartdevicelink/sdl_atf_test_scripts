---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3674
---------------------------------------------------------------------------------------------------
-- Description: Core sends a BC.OnAppRegistered notification to the HMI before setting up the 
-- internal HMI state for the app. If the HMI sends a notification (such as OnSystemRequest) to 
-- this app before the HMI state is set up, the app will not receive this notification.
--
-- Steps:
-- 1. Register an app
-- 2. HMI immediately starts PTU upon receiving OnAppRegistered
--
-- SDL does:
--  - send OnSystemRequest to the app once registration is completed, and PTU is completed
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local policyModes = {
  P  = "PROPRIETARY",
  EP = "EXTERNAL_PROPRIETARY",
  H  = "HTTP"
}

--[[ Local Functions ]]
local function getPTUFromPTS()
  local pTbl = common.sdl.getPTS()
  if pTbl == nil then
    utils.cprint(35, "PTS file was not found, PreloadedPT is used instead")
    pTbl = common.sdl.getPreloadedPT()
    if pTbl == nil then
      utils.cprint(35, "PreloadedPT was not found, PTU file has not been created")
      return nil
    end
  end
  if type(pTbl.policy_table) == "table" then
    pTbl.policy_table.consumer_friendly_messages = nil
    pTbl.policy_table.device_data = nil
    pTbl.policy_table.module_meta = nil
    pTbl.policy_table.usage_and_error_counts = nil
    pTbl.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
    pTbl.policy_table.module_config.preloaded_pt = nil
    pTbl.policy_table.module_config.preloaded_date = nil
    pTbl.policy_table.vehicle_data = nil
  else
    utils.cprint(35, "PTU file has incorrect structure")
  end
  return pTbl
end

local function policyTableUpdateProprietary()
  local ptuFileName = os.tmpname()
  local requestId = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })

  common.getHMIConnection():ExpectResponse(requestId)
  :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = common.sdl.getPTSFilePath() })
      local ptuTable = getPTUFromPTS()
      for i, _ in pairs(common.mobile.getApps()) do
        ptuTable.policy_table.app_policies[common.app.getPolicyAppId(i)] = common.ptu.getAppData(i)
      end
      if pPTUpdateFunc then
        pPTUpdateFunc(ptuTable)
      end
      utils.tableToJsonFile(ptuTable, ptuFileName)
    end)


  local lsEvent = common.run.createEvent()
  common.getHMIConnection():ExpectEvent(lsEvent, "Lock Screen URL event")
  local ptuEvent = common.run.createEvent()
  common.getHMIConnection():ExpectEvent(ptuEvent, "PTU event")
  for id, _ in pairs(common.mobile.getApps()) do
    common.getMobileSession(id):ExpectNotification("OnSystemRequest")
    :Do(function(_, d2)
        if d2.payload.requestType == "PROPRIETARY" then
          common.getHMIConnection():ExpectRequest("BasicCommunication.SystemRequest", { requestType = "PROPRIETARY" })
          :Do(function(_, d3)
              if not pExpNotificationFunc then
                common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
                common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
              end
              common.getHMIConnection():SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
              common.getHMIConnection():SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = d3.params.fileName })
            end)
          utils.cprint(35, "App ".. id .. " was used for PTU")
          common.getHMIConnection():RaiseEvent(ptuEvent, "PTU event")
          local corIdSystemRequest = common.getMobileSession(id):SendRPC("SystemRequest", {
            requestType = "PROPRIETARY" }, ptuFileName)
          common.getMobileSession(id):ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
          :Do(function() os.remove(ptuFileName) end)
        elseif d2.payload.requestType == "LOCK_SCREEN_ICON_URL" then
          common.getHMIConnection():RaiseEvent(lsEvent, "Lock Screen URL event")
        end
      end)
    :Times(AtMost(2))
  end
end

local function policyTableUpdateHttp()
  local ptuFileName = os.tmpname()
  local ptuTable = getPTUFromPTS()
  for i, _ in pairs(common.mobile.getApps()) do
    ptuTable.policy_table.app_policies[common.app.getPolicyAppId(i)] = common.ptu.getAppData(i)
  end
  utils.tableToJsonFile(ptuTable, ptuFileName)
  if not pExpNotificationFunc then
    common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
    common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
      { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" }):Times(3)
  end
  local cid = common.getMobileSession(ptuAppNum):SendRPC("SystemRequest",
    { requestType = "HTTP", fileName = "PolicyTableUpdate" }, ptuFileName)
  common.getMobileSession(ptuAppNum):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function() os.remove(ptuFileName) end)
end

local function policyTableUpdate()
  if pExpNotificationFunc then
    pExpNotificationFunc()
  end
  local policyMode = SDL.buildOptions.extendedPolicy
  if policyMode == policyModes.P or policyMode == policyModes.EP then
    policyTableUpdateProprietary(pPTUpdateFunc, pExpNotificationFunc)
  elseif policyMode == policyModes.H then
    policyTableUpdateHttp(pPTUpdateFunc, pExpNotificationFunc)
  end
end

local function registerAppWithPTU(pAppId, pMobConnId)
  if not pAppId then pAppId = 1 end
  if not pMobConnId then pMobConnId = 1 end
  local session = common.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams(pAppId).appName } })
      :Do(function(_, d1)
          common.setHMIAppId(d1.params.application.appID, pAppId)
          policyTableUpdate()
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
          :Times(AnyNumber())
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App With Immediate PTU", registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
