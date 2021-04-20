---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Two applications was registered with different appIDs and different appNames on a same mobile device.
-- After that second application calls for ChangeRegistration using same appName as first application has.
--
-- Precondition:
-- 1)SDL and HMI are started
-- 2)Mobile is connected to SDL
-- 3)First app registered from Mobile
-- 4)Second app registered from same Mobile with different appID and appName
--
-- Steps:
-- 1)Mobile sends ChangeRegistration request (with all mandatories) with same appName as first app has to SDL
--   Check:
--    SDL send ChangeRegistration(resultCode = "DUPLICATE_NAME") response to Mobile
--    SDL does not send OnAppRegistered notification to HMI
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
  [1] = { appName = "Test Application",   appID = "0001",  fullAppID = "0000001" },
  [2] = { appName = "Test Application 2", appID = "00022", fullAppID = "00000022" }
}

local changeRegParams = {
  [1] = {
    language ="EN-US",
    hmiDisplayLanguage ="EN-US",
    appName ="Test Application",
    ttsName = {
      {
        text ="SyncProxyTester",
        type ="TEXT",
      },
    },
    ngnMediaScreenAppName ="SPT",
    vrSynonyms = {
      "VRSyncProxyTester",
    }
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App2 from device 2", common.registerAppEx, {2, appParams[2], 1})

runner.Title("Test")
runner.Step("ChangeRegistration for App2 from the SAME device.",
  common.changeRegistrationNegative, {2, changeRegParams[1]}, "DUPLICATE_NAME")

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
