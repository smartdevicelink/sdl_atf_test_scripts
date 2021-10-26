---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3788
---------------------------------------------------------------------------------------------------
-- Description: Check SDL assigns RC permissions for the App in case:
-- - policy table contains an information about app with 'REMOTE_CONTROL' appHMIType
-- - app is registered with 'MEDIA' appHMIType
--
-- In case:
-- 1. RC functionality is allowed for App by policy
-- 2. 'REMOTE_CONTROL' appHMIType is assigned for the App by policy
-- 3. App is registered with 'MEDIA' appHMIType
-- 4. App is activated
-- 5. App sends valid SetInteriorVehicleData request
-- SDL does:
-- - allow App's remote-control RPCs (success:true, "SUCCESS")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local rc = require('user_modules/sequences/remote_control')
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local Variables ]]
local appSessionId1 = 1
local moduleType = "RADIO"

--[[ Local Functions ]]
local function getRCAppConfig(pPt)
  local out = utils.cloneTable(pPt.policy_table.app_policies.default)
  out.moduleType = rc.data.getRcModuleTypes()
  out.groups = { "Base-4", "RemoteControl" }
  out.AppHMIType = { "REMOTE_CONTROL" }
  return out
end

local function preparePreloadedPT()
  local preloadedTable = actions.sdl.getPreloadedPT()
  local appId = actions.app.getParams().fullAppID
  preloadedTable.policy_table.app_policies[appId] = getRCAppConfig(preloadedTable)
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  actions.sdl.setPreloadedPT(preloadedTable)
end

local function registerApp(pAppId)
  if not pAppId then pAppId = 1 end
  local session = actions.mobile.createSession(pAppId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", actions.app.getParams(pAppId))
      actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = actions.app.getParams(pAppId).appName, appType = { "REMOTE_CONTROL" }}})
      :Do(function(_, d1)
          actions.app.setHMIId(d1.params.application.appID, pAppId)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "WARNINGS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        end)
    end)
end

local function rpcAllowed(pModuleType, pAppId, pRpc)
  local moduleData = rc.predefined.getSettableModuleControlData(pModuleType)
  rc.rc.rpcSuccess(pModuleType, moduleData.moduleId, pAppId, pRpc, moduleData, false)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", actions.preconditions)
runner.Step("Update preloaded PT with RC app", preparePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", rc.rc.start)
runner.Step("RAI with MEDIA type, 'WARNINGS'", registerApp, { appSessionId1 })
runner.Step("Activate App", actions.app.activate, { appSessionId1 })

runner.Title("Test")
runner.Step("SetInteriorVehicleData SUCCESS", rpcAllowed,
  { moduleType, appSessionId1, "SetInteriorVehicleData", "SUCCESS" })

runner.Title("Postconditions")
runner.Step("Stop SDL", actions.postconditions)
