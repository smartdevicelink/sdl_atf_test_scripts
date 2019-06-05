---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Registration of two mobile applications with the different appNames and same appID from single mobile
--  device.
--
-- Precondition:
-- 1)SDL and HMI are started
-- 2)Mobile №1 and №2 are connected to SDL
--
-- Steps:
-- 1)Mobile sends RegisterAppInterface request (with all mandatories) to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = SUCCESS) response to Mobile
--    SDL sends OnAppRegistered notification to HMI
-- 2)Mobile sends RegisterAppInterface request (with all mandatories) with different appName and same appID to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = "APPLICATION_REGISTERED_ALREADY") response to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort }
}

local appParams = {
  [1] = { appName = "Test Application",   appID = "0001", fullAppID = "0000001" },
  [2] = { appName = "Test Application 2", appID = "0001", fullAppID = "0000001" }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})

runner.Title("Test")
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App2 from the same device 1",
  common.registerAppExNegative, {2, appParams[2], 1}, "APPLICATION_REGISTERED_ALREADY")

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
