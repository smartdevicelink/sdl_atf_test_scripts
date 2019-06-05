---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Check that same applications from different mobiles having the same appNames and different appIDs
-- successfully subscribe on different buttons while reporting different API versions.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL
-- 3) Mobile №1 sends RegisterAppInterface request (appID = 0001,  appName = "Test Application", api version = 4.5)
-- to SDL
-- 4) Mobile №2 sends RegisterAppInterface request (appID = 00022, appName = "Test Application", api version = 5.0)
-- to SDL
--
-- Steps:
-- 1) Mobile №1 App1 requests SubscribeButton ("PLAY_PAUSE")
--   Check:
--    SDL sends Buttons.OnButtonSubscription ( appId, isSubscribed = true, name = "PLAY_PAUSE" ) to HMI
--    SDL responds SubscribeButton (INVALID_DATA) to Mobile №1
-- 2) Mobile №2 App2 requests SubscribeButton ("PLAY_PAUSE")
--   Check:
--    SDL sends Buttons.OnButtonSubscription ( appId, isSubscribed = true, name = "PLAY_PAUSE" ) to HMI
--    SDL responds SubscribeButton (SUCCESS) to Mobile №2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
	[1] = { syncMsgVersion = { majorVersion = 4, minorVersion = 5 },
          appName        = "Test Application",
          appID          = "0001",
          fullAppID      = "0000001"
        },
	[2] = { syncMsgVersion = { majorVersion = 5, minorVersion = 0 },
          appName        = "Test Application",
          appID          = "00022",
          fullAppID      = "00000022"
        }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Set protocol version to 4", common.setProtocolVersion, { 4 })
runner.Step("Register App1 from device 1", common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Set protocol version to 5", common.setProtocolVersion, { 5 })
runner.Step("Register App2 from device 2", common.registerAppEx, { 2, appParams[2], 2 })

runner.Title("Test")
runner.Step("Activate App 1", common.app.activate, { 1 })
runner.Step("App1 from Mobile 1 requests Subscribe on PLAY_PAUSE",   common.subscribeOnButton,
  { 1, "PLAY_PAUSE", "INVALID_DATA" })
runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App2 from Mobile 2 requests Subscribe on PLAY_PAUSE", common.subscribeOnButton,
  { 2, "PLAY_PAUSE", "SUCCESS" })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
