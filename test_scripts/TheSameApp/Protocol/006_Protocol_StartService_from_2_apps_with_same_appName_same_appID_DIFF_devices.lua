---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Check how SDL responds when same applications from different mobiles having the same appNames and appIDs
-- send StartService requests using different protocol versions.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL
-- 3) Default protocol version is set into '2'
-- 4) Mobile №1 sends RegisterAppInterface request (appID = 0001,  appName = "Test Application", api version = 4.5)
-- to SDL
-- 5) Set protocol version into '3'
-- 6) Mobile №2 sends RegisterAppInterface request (appID = 00022, appName = "Test Application", api version = 5.0)
-- to SDL
--
-- Steps:
-- 1) Mobile №1 App1 send StartService request for Video streaming
--   Check:
--    SDL responds with StartServiceNACK to Mobile №1
-- 2) Mobile №2 App2 send StartService request for Video streaming
--   Check:
--    SDL sends Navigation.StartStream Video streaming request to HMI
--    SDL responds with StartServiceACK to Mobile №2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = { syncMsgVersion     = { majorVersion = 2, minorVersion = 0 },
          isMediaApplication = true,
          appName            = "Test Application",
          appID              = "0001",
          fullAppID          = "0000001"
        },
  [2] = { syncMsgVersion     = { majorVersion = 3, minorVersion = 0 },
          isMediaApplication = true,
          appName            = "Test Application",
          appID              = "0001",
          fullAppID          = "0000001"
        }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1",    common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Set protocol version to 3", common.setProtocolVersion, { 3 })
runner.Step("Register App2 from device 2",    common.registerAppEx, { 2, appParams[2], 2 })

runner.Title("Test")
runner.Step("Activate App 1", common.app.activate, { 1 })
runner.Step("App1 from Mobile 1 requests StartService for Video streaming", common.startVideoServiceNACK, { 1 })
runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App2 from Mobile 2 requests StartService for Video streaming", common.startVideoService, { 2 })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
