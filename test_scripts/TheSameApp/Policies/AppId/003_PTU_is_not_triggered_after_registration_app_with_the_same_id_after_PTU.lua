---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3136
--
-- Description: Check that SDL defines the same application from second device as known one
-- and does not trigger the PTU for second app after first PTU is finished
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL and are consented
-- 3) App1 is registered from Mobile №1 and triggers PTU
-- 4) PTU for App1 from Mobile №1 is performed successful
--
-- Steps:
-- 1) App1 is registered from Mobile №2
--   Check: SDL does not trigger new PTU: does not send SDL.OnStatusUpdate and BC.PolicyUpdate to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = {
    appName = "Test App",
    isMediaApplication = true,
    appHMIType = { "NAVIGATION" },
    appID = "0008",
    fullAppID = "0000008"
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})

runner.Title("Test")
runner.Step("Register App1 from device 1", common.registerAppWithPTU, { 1, appParams[1], 1 })
runner.Step("PTU", common.ptu.policyTableUpdate)
runner.Step("Register App1 from device 2", common.registerAppWithoutPTU, { 2, appParams[1], 2 })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
