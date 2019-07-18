---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received AUDIO module capabilities with "moduleId" parameter omitted in one of modules from HMI.
--  Check that in this case SDL should send default capabilities in "GetSystemCapability" response to mobile
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent AUDIO module capabilities having one of mandatory parameter omitted to SDL
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
local rcCapabilities = {}
for _, v in pairs(common.getRcModuleTypes()) do rcCapabilities[v] = common.DEFAULT end

local customAudioCapabilities = {
  {
    moduleName = "Audio Driver Seat",
    moduleInfo = {
      moduleId = "0876b4be-f1ce-4f5c-86e9-5ca821683a1b",
      location    = { col = 0, row = 0 },
      serviceArea = { col = 0, row = 0 },
      allowMultipleAccess = true
    }
  },
  {
    moduleName = "Audio Front Passenger Seat",
    moduleInfo = {
    --  moduleId = "d77a4bd2-5bd2-4c5a-991a-7ec5f14911ca",                       -- omitted mandatory parameter
      location    = { col = 2, row = 0 },
      serviceArea = { col = 2, row = 0 },
      allowMultipleAccess = true
    }
  },
  {
    moduleName = "Audio Upper Level Vehicle Interior",
    moduleInfo = {
      moduleId = "726827ed-d6be-47d7-a8cc-4723f333b009",
      location    = { col = 0, row = 0, level = 1 },
      serviceArea = { col = 0, row = 0, level = 1 },
      allowMultipleAccess = true
    }
  }
}
rcCapabilities.AUDIO = customAudioCapabilities

local expectedParameters = common.getExpectedParameters()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set default RC capabilities", common.updateDefaultHmiCapabilities )
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability Absent moduleInfo mandatory parameter",
  common.sendGetSystemCapability, { 1, "REMOTE_CONTROL", expectedParameters })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
