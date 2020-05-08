---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Two mobile applications with the same appNames from different mobiles do subscribing on different
-- buttons and receive OnButtonEvent and OnButtonPress notifications in different cases.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobiles №1 and №2 are connected to SDL
--
-- Steps:
-- 1) Mobile №1 App1 requested Subscribe on "OK" button
--   Check:
--    SDL sends Buttons.SubscribeButton("OK", appId_1) to HMI
--    SDL receives Buttons.SubscribeButton("SUCCESS") response from HMI
--    SDL sends SubscribeButton("SUCCESS") response to Mobile №1
--    SDL sends OnHashChange with updated hashId to Mobile №1
-- 2) HMI sent OnButtonEvent and OnButtonPress notifications for "OK" button
--   Check:
--    SDL sends OnButtonEvent("OK") and OnButtonPress("OK") notifications to Mobile №1
--    SDL does NOT send OnButtonEvent and OnButtonPress to Mobile №2
-- 3) Mobile №2 App2 requested Subscribe on "PLAY_PAUSE" button
--   Check:
--    SDL sends Buttons.SubscribeButton("PLAY_PAUSE", appId_2) to HMI
--    SDL receives Buttons.SubscribeButton("SUCCESS") response from HMI
--    SDL sends SubscribeButton("SUCCESS") response to Mobile №2
--    SDL sends OnHashChange with updated hashId to Mobile №2
-- 4) HMI sent OnButtonEvent and OnButtonPress notifications for "PLAY_PAUSE" button
--   Check:
--    SDL sends OnButtonEvent("PLAY_PAUSE") and OnButtonPress("PLAY_PAUSE") notifications to Mobile №2
--    SDL does NOT send OnButtonEvent and OnButtonPress to Mobile №1
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
  [1] = { appName = "Test Application", appID = "0001",  fullAppID = "0000001" },
  [2] = { appName = "Test Application", appID = "00022", fullAppID = "00000022" }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Register App2 from device 2", common.registerAppEx, { 2, appParams[2], 2 })

runner.Title("Test")
runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("Send App 2 to LIMITED HMI level", common.hmiLeveltoLimited, { 2 })
runner.Step("Activate App 1", common.app.activate, { 1 })
runner.Step("App1 from Mobile 1 requests Subscribe on OK", common.subscribeOnButton, {1, "OK", "SUCCESS" })
runner.Step("HMI send OnButtonEvent and OnButtonPress for OK", common.sendOnButtonEventPress, { 1, 2, "OK", 1 })

runner.Step("Send App 1 to LIMITED HMI level", common.hmiLeveltoLimited, { 1 })
runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App2 from Mobile 2 requests Subscribe on PLAY_PAUSE",
  common.subscribeOnButton, { 2, "PLAY_PAUSE", "SUCCESS" })
runner.Step("HMI send OnButtonEvent and OnButtonPress for PLAY_PAUSE",
  common.sendOnButtonEventPress, { 2, 1, "PLAY_PAUSE", 1 })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
