---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sent "SetInteriorVehicleData" request containing incorrect value of "moduleId" to the SDL.
--  SDL should decline this request answering with (resultCode = "UNSUPPORTED_RESOURCE").
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "SetInteriorVehicleData"(moduleType = "LIGHT", moduleId = "incorrect_value", lightControlData) request
--    to the SDL
--   Check:
--    SDL does NOT resend "RC.SetInteriorVehicleData" request to the HMI
--    SDL responds with "SetInteriorVehicleData"(success = false, resultCode = "UNSUPPORTED_RESOURCE") to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = { LIGHT = common.DEFAULT }
local requestModuleData = {
  moduleType = "LIGHT",
  moduleId = "incorrect_value",
  lightControlData = {
    lightState = {
      { id = "FRONT_LEFT_HIGH_BEAM", status = "OFF"}
    }
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.customModulesPTU, { "LIGHT" })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send SetInteriorVehicleData rpc for LIGHT module with incorrect moduleId",
  common.rpcReject,{"LIGHT", "incorrect_value", 1, "SetInteriorVehicleData", requestModuleData, "UNSUPPORTED_RESOURCE"})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
