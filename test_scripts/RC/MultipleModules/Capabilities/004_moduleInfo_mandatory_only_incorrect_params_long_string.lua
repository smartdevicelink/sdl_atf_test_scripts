  ---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  SDL received RADIO module capabilities containing "moduleId" parameter which string value exceeds the limit
--  of string length permitted to this parameter. In this case SDL should send default capabilities with the
--  "GetSystemCapability" response to mobile App
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent RADIO module capabilities with invalid mandatory parameters to SDL
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

local longString = string.rep("a", 101)
local customRadioCapabilities = {
  {
    moduleName = "Radio Driver Seat",
    moduleInfo = { moduleId = longString }                        --invalid value
  }
}
rcCapabilities.RADIO = customRadioCapabilities

local expectedParameters = common.getExpectedParameters()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set default RC capabilities", common.updateDefaultHmiCapabilities )
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability Incorrect moduleInfo mandatory parameter",
  common.sendGetSystemCapability, { 1, "REMOTE_CONTROL", expectedParameters })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
