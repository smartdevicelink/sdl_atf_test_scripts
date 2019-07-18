---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sent "SetInteriorVehicleData" request with correct "moduleId" value and incorrect other mandatory
--  parameter's value to the SDL.
--  SDL should decline this request answering with (resultCode = "INVALID_DATA").
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to SDL
-- 3) Mobile is connected to SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "SetInteriorVehicleData"
--    (moduleType = "LIGHT", moduleId = "f31ef579", lightControlData = {"invalid_value"}) request to SDL
--   Check:
--    SDL does NOT resend "RC.SetInteriorVehicleData" request to HMI
--    SDL responds to the App with "SetInteriorVehicleData"(success = false, resultCode = "INVALID_DATA")
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
  moduleId = common.getRcCapabilities().LIGHT.moduleInfo.moduleId,
  lightControlData = {
    lightState = {
      { id = "invalid_value", status = "OFF"}                 -- invalid value of "id"
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
runner.Step("Send SetInteriorVehicleData rpc for LIGHT module with incorrect moduleId", common.rpcReject,
  { "LIGHT", requestModuleData.moduleId, 1, "SetInteriorVehicleData", requestModuleData, "INVALID_DATA"})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
