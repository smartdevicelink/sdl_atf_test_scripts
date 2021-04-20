---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3267
--
-- Steps:
-- 1. Make sure 'url' is defined in PT in 'endpoints' section
-- 2. Start SDL, HMI, connect Mobile device
-- 3. Register mobile application
-- SDL does:
--  - send 'OnSystemRequest(LOCK_SCREEN_ICON_URL)' notification
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local numOfApps = 200
local appParams = utils.cloneTable(common.app.getParams(1))

--[[ Local Functions ]]
local function registerAppWOPTU(pAppId)
  appParams.appName = "App_" .. pAppId
  appParams.appID = "000" .. pAppId
  appParams.fullAppID = "000000" .. pAppId
  config["application" .. pAppId] = { registerAppInterfaceParams = appParams }
  local mobileSession = common.getMobileSession(pAppId)
  mobileSession:StartService(7)
  :Do(function()
    local corId = mobileSession:SendRPC("RegisterAppInterface", appParams)
    common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
    mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      mobileSession:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
    end)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for i = 1, numOfApps do
  runner.Step("Register App " .. i, registerAppWOPTU, { i })
  runner.Step("Unregister App " .. i, common.app.unRegister, { i })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
