---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3715
---------------------------------------------------------------------------------------------------
-- Description: SDL only accepts PTU from application which was sent OnSystemRequest
--
-- Steps:
-- 1. Core and HMI are started
-- 2. An application is registered
-- 3. Core sends OnStatusUpdate UPDATING
-- 4. Before OnSystemRequest is sent to any app, app 1 attempts SystemRequest PTU
-- SDL does:
--  - reject the PTU, responding success false REJECTED
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local SDL = require('SDL')
local utils = require('user_modules/utils')
local runner = require('user_modules/script_runner')
local common = require('test_scripts/AppServices/commonAppServices')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]

--[[ Local Functions ]]
local function ptuWrongApp()
  local session = common.mobile.createSession(1, 1)
  session:StartService(7)
  :Do(function()
    local corId = session:SendRPC("RegisterAppInterface", common.app.getParams(1))
    common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
      { application = { appName = common.app.getParams(1).appName } })
    :Do(function(_, d1)
        local appId = 1
        if d1.params.application.appName == common.app.getParams(2).appName then
          appId = 2
        end
        common.app.setHMIId(d1.params.application.appID, appId)
      end)
    session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      common.isPTUStarted()
        session:ExpectNotification("OnHMIStatus",
          { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        session:ExpectNotification("OnPermissionsChange")
        :Times(AnyNumber())
      end)
  end)

  common.hmi.getConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" },
    { status = "UPDATING" })
  :Times(2)
  :Do(function(_, d)
    if d.params.status == "UPDATING" then
      local ptuFileName = os.tmpname()
      local ptuTable = common.getPTUFromPTS()
      for i, _ in pairs(common.mobile.getApps()) do
        ptuTable.policy_table.app_policies[common.app.getPolicyAppId(i)] = common.ptu.getAppData(i)
      end
      utils.tableToJsonFile(ptuTable, ptuFileName)
      local corId3 = common.mobile.getSession(1):SendRPC("SystemRequest", { requestType = "PROPRIETARY" }, ptuFileName)
      common.mobile.getSession(1):ExpectResponse(corId3, { success = false, resultCode = "REJECTED" })
      :Do(function() os.remove(ptuFileName) end)
    end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register two apps and PTU from the wrong app", ptuWrongApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
