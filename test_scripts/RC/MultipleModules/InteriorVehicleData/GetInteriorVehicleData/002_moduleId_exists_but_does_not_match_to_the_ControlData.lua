 ---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sent "GetInteriorVehicleData" request containing incorrect value of "moduleId" to the SDL.
--  SDL should decline this request answering with (resultCode = "UNSUPPORTED_RESOURCE").
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all module capabilities with custom CLIMATE ones to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetInteriorVehicleData"(moduleType = "CLIMATE", moduleId = "incorrect_value") request to the SDL
--   Check:
--    SDL does NOT resend "RC.GetInteriorVehicleData" request to the HMI
--    SDL responds with "GetInteriorVehicleData"(success = false, resultCode = "UNSUPPORTED_RESOURCE") to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local customClimateCapabilities = {
  {
    moduleName = "Climate Driver Seat",
    moduleInfo = {
      moduleId = "2df6518c-ca8a-4e7c-840a-0eba5c028351",
      location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
      serviceArea = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
      allowMultipleAccess = true
    },
    acEnableAvailable = true,
    autoModeEnableAvailable = false,
    fanSpeedAvailable = true
  },
  {
    moduleName = "Climate Front Passenger Seat",
    moduleInfo = {
      moduleId = "4c133291-3cc2-4174-b722-6284953af345",
      location = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
      serviceArea = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
      allowMultipleAccess = true,
    },
    autoModeEnableAvailable = true
  }
}
local rcCapabilities = { CLIMATE = customClimateCapabilities }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.customModulesPTU, { "CLIMATE" })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send GetInteriorVehicleData rpc for CLIMATE module with incorrect moduleId",
  common.rpcReject, { "CLIMATE", "incorrect_value", 1, "GetInteriorVehicleData", true, "UNSUPPORTED_RESOURCE"})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
