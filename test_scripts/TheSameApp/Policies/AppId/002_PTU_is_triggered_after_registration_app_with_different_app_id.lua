---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3136
--
-- Description: Check that SDL triggers new PTU for App2 from Mobile №2 after
-- the first PTU for App1 from Mobile №1 is finished in case App2 is registered during first PTU
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL and are consented
-- 3) App1 is registered from Mobile №1 and triggers PTU
--
-- Steps:
-- 1) App2 is registered from Mobile №2 during PTU for App1 from Mobile №1 is in progress
--   Check: SDL does not send SDL.OnStatusUpdate and BC.PolicyUpdate to HMI during the app registration
-- 2) First PTU is performed successful
--   Check: SDL triggers new PTU after the first one is finished
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

local function secondPTUIsTriggered()
  common.isPTUStarted()
  common.hmi.getConnection():ExpectRequest("SDL.OnStatusUpdate",
    { status = "UP_TO_DATE" }, { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(3)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})

runner.Title("Test")
runner.Step("Register App1 from device 1", common.registerAppWithPTU, { 1, appParams[1], 1 })
runner.Step("Register App2 from device 2", common.registerAppWithoutPTU, { 2, appParams[2], 2 })
runner.Step("PTU 1", common.ptu.policyTableUpdate, { nil, secondPTUIsTriggered })
runner.Step("PTU 2", common.ptu.policyTableUpdate)

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
