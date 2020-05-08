---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  HMI sent capabilities, where CLIMATE has three modules, to the SDL.
--  Mobile App sends "SetInteriorVehicleData" request with omitted "moduleId" parameter.
--  During transferring it to the HMI SDL should add the default "moduleId" value to the request and use this parameter
--  in further communication with HMI and App.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "SetInteriorVehicleData"(moduleType = "CLIMATE", climateControlData) request to the SDL
--   Check:
--    SDL resends "RC.SetInteriorVehicleData"(moduleType = "CLIMATE", moduleId = "2df6518c", climateControlData) request
--     adding the default "moduleId" value to the HMI
--    HMI sends "RC.SetInteriorVehicleData"(moduleType = "CLIMATE", moduleId ="2df6518c", climateControlData) response
--     to the SDL
--    SDL resends "SetInteriorVehicleData"
--     (moduleType = "CLIMATE", moduleId = "2df6518c", climateControlData, resultCode = "SUCCESS") response to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = { CLIMATE = common.DEFAULT}
local subscribeData = { CLIMATE = common.getRcCapabilities().CLIMATE[1].moduleInfo.moduleId }
local requestModuleData = {
  CLIMATE = {
    moduleType = "CLIMATE",
    climateControlData = {
      fanSpeed = 50,
      desiredTemperature = {
        unit = "CELSIUS",
        value = 10.5
      },
      acEnable = true,
      autoModeEnable = true
    }
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for moduleType, moduleId in pairs(subscribeData) do
  runner.Step("Send request for "..moduleType.." module", common.sendSuccessRpcNoModuleId,
    { moduleType, moduleId, 1, "SetInteriorVehicleData", requestModuleData[moduleType],  })
end
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
