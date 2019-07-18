---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sent "SetInteriorVehicleData" request containing "moduleId" of incorrect data type to the SDL.
--  SDL should decline this request answering with (resultCode = "INVALID_DATA").
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "SetInteriorVehicleData"(moduleType = "HMI_SETTINGS", moduleId = invalid_value, hmiSettingsControlData)
--    request to the SDL
--   Check:
--    SDL does NOT resend "RC.SetInteriorVehicleData" request to the HMI
--    SDL responds with "SetInteriorVehicleData"(success = false, resultCode = "INVALID_DATA") to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = { HMI_SETTINGS = common.DEFAULT }
local invalid_values = { true, {1, 2, 3}, 1234, common.EMPTY_ARRAY }
local requestModuleData = {
  moduleType = "HMI_SETTINGS",
  hmiSettingsControlData = {
    displayMode = "AUTO",
    temperatureUnit = "FAHRENHEIT",
    distanceUnit = "MILES"
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.customModulesPTU, { "HMI_SETTINGS" })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for key, invValue in pairs(invalid_values) do
  local testModuleData = {}
  testModuleData[key] = common.cloneTable(requestModuleData)
  testModuleData[key].moduleId = invValue
  runner.Step("Send SetInteriorVehicleData rpc for HMI_SETTINGS with invalid "..type(invValue).." moduleId",
    common.rpcReject, { "HMI_SETTINGS", invValue, 1, "SetInteriorVehicleData", testModuleData[key], "INVALID_DATA"})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
