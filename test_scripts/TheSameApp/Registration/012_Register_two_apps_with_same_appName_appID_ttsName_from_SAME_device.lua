---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Two mobile applications with the same appNames, same appIDs and same ttsName are registering from a same mobile
-- device. Check if an OnAppRegistered notification will be sent for the first app and will NOT be sent for the second
-- app.
--
-- Precondition:
-- 1)SDL and HMI are started
-- 2)Mobile is connected to SDL
--
-- Steps:
-- 1)Mobile sends RegisterAppInterface request (with all mandatories) with appID = 0001, appName = "Test Application"
--    and ttsName = "TtsName" to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = SUCCESS) response to Mobile
--    SDL sends OnAppRegistered(application.appName = "first_app", ttsName = "TtsName") notification to HMI
-- 2)Mobile sends RegisterAppInterface request (with all mandatories) with appID = 0022, appName = "Test Application 2"
--    and ttsName = "TtsName" to SDL
--   Check:
--    SDL sends RegisterAppInterface(resultCode = "DUPLICATE_NAME") response to Mobile
--    SDL does not send OnAppRegistered(application.appName = "second_app", ttsName = "TtsName") notification to HMI from Mobile
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
  [1] = { appName   = "Test Application",
          appID     = "0001",
          fullAppID = "0000001",
          ttsName   = {
            {
              text ="TtsName",
              type ="TEXT"
            }
          }
        },
  [2] = { appName   = "Test Application 2",
          appID     = "00022",
          fullAppID = "00000022",
          ttsName   = {
            {
              text ="TtsName",
              type ="TEXT"
            }
          }
        }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})

runner.Title("Test")
runner.Step("Register App1 from device 1", common.registerAppExTtsName, {1, appParams[1], 1})
runner.Step("Register App2 from device 2", common.registerAppExNegative, {2, appParams[2], 1, "DUPLICATE_NAME"})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
