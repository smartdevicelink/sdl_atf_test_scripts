---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received HMI_SETTINGS module capabilities, where "moduleInfo" contains "serviceArea" with incorrect mandatory
--  parameter. SDL should send default capabilities in "GetSystemCapability" response to mobile
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent HMI_SETTINGS module capabilities to SDL
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
local customHmiSettingsCapabilities = {
  moduleName = "HmiSettings Driver Seat",
  moduleInfo = {
    moduleId = "fd68f1ef-95ce-4468-a304-4c864a0e34a1",
    location = { col = 0, row = 0 },
    serviceArea = { col = "string", row = 0 },            --invalid value of "col"
  }
}

local capabilityParams = { HMI_SETTINGS = customHmiSettingsCapabilities }
local expectedParameters = common.getExpectedParameters()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set default RC capabilities", common.updateDefaultHmiCapabilities )
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { capabilityParams })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability Incorrect Grid serviceArea parameter in HMI_SETTINGS module",
  common.sendGetSystemCapability, { 1, "REMOTE_CONTROL", expectedParameters })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
