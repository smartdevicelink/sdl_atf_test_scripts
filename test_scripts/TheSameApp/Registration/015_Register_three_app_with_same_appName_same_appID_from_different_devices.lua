---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Registration of three mobile applications with the same appName and same appID from different mobile
--  devices
--
-- Precondition:
-- 1)SDL and HMI are started
-- 2)Mobile №1, №2 and №3 are connected to SDL
--
-- Steps:
-- 1)Mobile №1 sends RegisterAppInterface request (with all mandatories) to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = SUCCESS) response to Mobile №1
--    SDL sends OnAppRegistered notification to HMI
-- 2)Mobile №2 sends RegisterAppInterface request (with all mandatories) with the same appName and same appID to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = SUCCESS) response to Mobile №2
--    SDL sends OnAppRegistered notification to HMI
-- 3)Mobile №3 sends RegisterAppInterface request (with all mandatories) with the same appName and same appID to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = SUCCESS) response to Mobile №3
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
}

local appParams = {
  [1] = { appName = "Test Application", appID = "0001", fullAppID = "0000001" },
  [2] = { appName = "Test Application", appID = "0001", fullAppID = "0000001" },
  [3] = { appName = "Test Application", appID = "0001", fullAppID = "0000001" }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})

runner.Title("Test")
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App1 from device 2", common.registerAppEx, {2, appParams[2], 2})
runner.Step("Register App1 from device 3", common.registerAppEx, {3, appParams[3], 3})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
