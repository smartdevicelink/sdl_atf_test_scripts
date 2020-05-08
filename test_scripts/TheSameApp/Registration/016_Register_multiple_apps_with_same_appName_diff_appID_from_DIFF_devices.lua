---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Registration of multiple mobile applications with the same appName
--  and different/or appIDs from different mobile devices
--
-- Precondition:
-- 1)SDL and HMI are started
-- 2)Mobile №1, №2, №3 and №4 are connected to SDL
--
-- Steps:
-- 1)Mobile №1 sends RegisterAppInterface request (with all mandatories) to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = SUCCESS) response to Mobile №1
--    SDL sends OnAppRegistered notification to HMI
-- 2)Mobile №2 sends RegisterAppInterface request (with all mandatories) with the same appName and different appID
--    as application from Mobile №1 to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = SUCCESS) response to Mobile №2
--    SDL sends OnAppRegistered notification to HMI
-- 3)Mobile №3 sends RegisterAppInterface request (with all mandatories) with the same appID and different appName
--    as application from Mobile №2 to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = SUCCESS) response to Mobile №3
--    SDL sends OnAppRegistered notification to HMI
-- 4)Mobile №4 sends RegisterAppInterface request (with all mandatories) with the same appName and appID
--    as application from Mobile №1 to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = SUCCESS) response to Mobile №4
--    SDL sends OnAppRegistered notification to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort },
  [3] = { host = "10.42.0.1",       port = config.mobilePort },
  [4] = { host = "8.8.8.8",         port = config.mobilePort }
}

local appParams = {
	[1] = { appName = "Test Application",   appID = "0001",  fullAppID = "0000001" },
	[2] = { appName = "Test Application",   appID = "00022", fullAppID = "00000022" },
	[3] = { appName = "Test Application 2", appID = "00022", fullAppID = "00000022" },
	[4] = { appName = "Test Application",   appID = "0001",  fullAppID = "0000001" }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})

runner.Title("Test")
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App2 from device 2", common.registerAppEx, {2, appParams[2], 2})
runner.Step("Register App3 from device 3", common.registerAppEx, {3, appParams[3], 3})
runner.Step("Register App4 from device 4", common.registerAppEx, {4, appParams[4], 4})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
