---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received AUDIO module capabilities, where "moduleInfo" has incorrect optional parameter in "location" structure.
--  SDL should send default capabilities in "GetSystemCapability" response to mobile
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent AUDIO module capabilities to SDL
-- 3) Mobile is connected to SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetSystemCapability" request ("REMOTE_CONTROL")
--   Check:
--    SDL sends "GetSystemCapability" response with default capabilities to mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local customAudioCapabilities = {
  {
    moduleName = "Audio Driver Seat",
    moduleInfo = {
      moduleId    = "0876b4be-f1ce-4f5c-86e9-5ca821683a1b",
      location    = { col = 0, row = 0, level = "string" },      --invalid value
      serviceArea = { col = 0, row = 0, level = 0 },
      allowMultipleAccess = false
    }
  },
  {
    moduleName = "Audio Front Passenger Seat",
    moduleInfo = {
      moduleId = "d77a4bd2-5bd2-4c5a-991a-7ec5f14911ca",
      location    = { col = 0, row = 0, level = 0 },
      serviceArea = { col = 0, row = 0, level = 0 },
      allowMultipleAccess = true
    }
  }
}

local capabilityParams = { AUDIO = customAudioCapabilities }
local expectedParameters = common.getExpectedParameters()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set default RC capabilities", common.updateDefaultHmiCapabilities )
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { capabilityParams })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability Grid invalid optional parameter in location in AUDIO module",
  common.sendGetSystemCapability, { 1, "REMOTE_CONTROL", expectedParameters })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
