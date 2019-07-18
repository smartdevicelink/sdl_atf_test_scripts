---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  HMI sent to SDL capabilities where CLIMATE has three modules. Mobile App requested subscription to CLIMATE module
--  sending "GetInteriorVehicleData" request with omitted "moduleId" parameter.
--  SDL should transfer it to the HMI adding a default "moduleId" value to the request and use it in further
--  communications.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "GetInteriorVehicleData"(moduleType = "CLIMATE", subscribe = true) request
--   Check:
--    SDL resends "RC.GetInteriorVehicleData"(moduleType = "CLIMATE", moduleId = "2df6518c", subscribe = true)
--     request to the HMI, adding the default "2df6518c" value
--    HMI sends "RC.GetInteriorVehicleData"
--     (moduleType = "CLIMATE", moduleId = "2df6518c", climateControlData, isSubscribed = true) response to the SDL
--    SDL resends "GetInteriorVehicleData"
--     (moduleType = "CLIMATE", moduleId = "2df6518c", climateControlData, resultCode = "SUCCESS")
--     response to the App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rcCapabilities = { CLIMATE = common.DEFAULT }
local subscribeData = { CLIMATE = common.getRcCapabilities().CLIMATE[1].moduleInfo.moduleId }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.customModulesPTU, { "CLIMATE" })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for moduleType, moduleId in pairs(subscribeData) do
  runner.Step("Send GetInteriorVehicleData request with omitted moduleId for ".. moduleType .." module",
    common.subscribeToIVDataNoModuleId, { moduleType, moduleId, 1, true, "SUCCESS" })
end
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
