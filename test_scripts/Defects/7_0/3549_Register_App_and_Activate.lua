---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3549
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. App is registered
-- 2. HMI activates app just after receiving 'BC.OnAppRegistered' notification
-- SDL does
--  - send 2 OnHMIStatus notifications to App: NONE, FULL
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

-- [[ Local Variables ]]

-- [[ Local Functions ]]
local function registerAppAndActivate()
  local session = common.mobile.createSession()
  session:StartService(7)
  :Do(function()
      local cid = session:SendRPC("RegisterAppInterface", common.app.getParams())
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      :Do(function(_, data)
          common.app.setHMIId(data.params.application.appID)
          local cid2 = common.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = common.app.getHMIId() })
          common.hmi.getConnection():ExpectResponse(cid2)
        end)
      session:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
      session:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE" }, { hmiLevel = "FULL" })
      :Times(2)
    end)
  common.run.wait(1000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app and activate", registerAppAndActivate)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
