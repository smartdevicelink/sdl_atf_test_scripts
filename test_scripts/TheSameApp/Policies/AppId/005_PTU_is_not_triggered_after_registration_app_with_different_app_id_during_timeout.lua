---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3136
--
-- Description: Check that SDL does not trigger 2nd PTU for App2 from Mobile №2 after
-- the first PTU for App1 from Mobile №1 is finished in case App1 and App2 are registered
-- within 'ApplicationListUpdateTimeout'
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL and are consented
-- 3) App1 is registered from Mobile №1 and triggers PTU
--
-- Steps:
-- 1) App2 is registered from Mobile №2 within 'ApplicationListUpdateTimeout'
-- during PTU for App1 from Mobile №1 is in progress
--   Check: SDL does not send SDL.OnStatusUpdate and BC.PolicyUpdate to HMI during the app registration
-- 2) First PTU is performed successful
--   Check: SDL does not trigger new PTU after the first one is finished
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
    appName = "Test Appl",
    isMediaApplication = true,
    appHMIType = { "DEFAULT" },
    appID = "0009",
    fullAppID = "0000009"
  },
  [2] = {
    appName = "Test Appl",
    isMediaApplication = true,
    appHMIType = { "DEFAULT" },
    appID = "0010",
    fullAppID = "0000010"
  }
}

local function registerApp1()
  common.hmi.getConnection():ExpectRequest("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })
  common.registerAppEx(1, appParams[1], 1, false)
end

local function registerApp2()
  common.registerAppEx(2, appParams[2], 2, true)
  common.hmi.getConnection():ExpectRequest("SDL.OnStatusUpdate", { status = "UPDATING" })
end

local function secondPTUIsNotTriggered()
  common.isPTUNotStarted()
  common.run.wait(5000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})

runner.Title("Test")
runner.Step("Register App1 from device 1 - No PTU before ApplicationListUpdateTimeout is expired", registerApp1)
runner.Step("Register App2 from device 2 - PTU started after ApplicationListUpdateTimeout is expired", registerApp2)
runner.Step("PTU", common.ptu.policyTableUpdate, { nil, secondPTUIsNotTriggered })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
