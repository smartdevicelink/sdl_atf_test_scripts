---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App subscribes to two CLIMATE modules, one of them defined as "default".
--  Check that in case of sending "GetInteriorVehicleData" request without "moduleId", SDL will transfer it adding
--  default value of "moduleId".
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
-- 5) App is subscribed to two CLIMATE modules with moduleId = "2df6518c" and moduleId = "b468c01c"
--
-- Steps:
-- 1) App sends "GetInteriorVehicleData"(moduleType = "CLIMATE", subscribe = false) request to the SDL
--   Check:
--    SDL resends "RC.GetInteriorVehicleData"(moduleType = "CLIMATE", moduleId = "2df6518c", subscribe = false)
--     request to HMI, adding a default "2df6518c" value
--    HMI sends "RC.GetInteriorVehicleData"
--     (moduleType = "CLIMATE", moduleId = "2df6518c", climateControlData, isSubscribed = false) response to the SDL
--    SDL resends "GetInteriorVehicleData"
--     (moduleType = "CLIMATE", moduleId = "2df6518c", climateControlData, isSubscribed = false) response to the App
-- 2) After some changes were made to the "2df6518c" module HMI sends "RC.OnInteriorVehicleData"
--     (moduleType = "CLIMATE", moduleId = "2df6518c", climateControlData) notification to the SDL
--   Check:
--    SDL does not send any notification to the App
-- 3) After some changes were made to the b468c01c module HMI sends "RC.OnInteriorVehicleData"
--     (moduleType = "CLIMATE", moduleId = "b468c01c", climateControlData) notification to the SDL
--   Check:
--    SDL resends OnInteriorVehicleData (moduleType = "CLIMATE", moduleId = "b468c01c", climateControlData)
--     notification to the App
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
    fanSpeedAvailable = true,
    desiredTemperatureAvailable = true,
    acEnableAvailable = true,
    autoModeEnableAvailable = true
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
  },
  {
    moduleName = "Climate 2nd Raw",
    moduleInfo = {
      moduleId = "b468c01c-9346-4331-bd4f-927ca97f0103",
        location    = { col = 0, row = 1 },
        serviceArea = { col = 0, row = 1 }
    },
    fanSpeedAvailable = true,
    desiredTemperatureAvailable = true,
    acEnableAvailable = true,
    autoModeEnableAvailable = true
  }
}
local rcCapabilities = { CLIMATE = customClimateCapabilities }
local climateDataToSet = {
  moduleType = "CLIMATE",
  climateControlData = {
    fanSpeed = 44,
    desiredTemperature = {
      unit = "CELSIUS",
      value = 22.5
    },
    acEnable = true,
    autoModeEnable = false
  }
}
local updateData = {
  -- the app successfully unsubscribes from the "2df6518c" module by default
  { moduleId = customClimateCapabilities[1].moduleInfo.moduleId, isSubscribed = false },
  -- but remains subscribed to the "b468c01c" module
  { moduleId = customClimateCapabilities[3].moduleInfo.moduleId, isSubscribed = true }
}
local defaultModuleId = updateData[1].moduleId

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe on CLIMATE module by sending moduleType and moduleId",
  common.subscribeToModule, { "CLIMATE", updateData[1].moduleId, 1 })
runner.Step("Subscribe on another CLIMATE module by sending moduleType and moduleId",
  common.subscribeToModule, { "CLIMATE", updateData[2].moduleId, 1 })

runner.Title("Test")
runner.Step("Unsubscribe from CLIMATE module by sending moduleType only",
  common.rpcWithModuleIdOmitted, { 1, "CLIMATE", defaultModuleId, false })

for key, data in pairs(updateData) do
  local testModuleData = {}
  testModuleData[key] = common.cloneTable(climateDataToSet)
  testModuleData[key].moduleId = data.moduleId
  runner.Step("Check whether we receive notifications or not after changes made in "..data.moduleId.." CLIMATE module",
    common.isSubscribed, { "CLIMATE", data.moduleId, 1, data.isSubscribed, testModuleData[key] })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
