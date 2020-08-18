---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data after IGN_OFF in case GetInteriorVehicleData was requested
--  in case app was subscribed to some of modules (one of each module type)
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to all modules via GetInteriorVehicleData(moduleType, moduleId)
--
-- Sequence:
-- 1. IGN_OFF and IGN_ON are performed
-- 2. App starts registration with actual hashId after SDL restart
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(subscribe=true, moduleType,moduleId) to HMI
--    during resumption data for each previously subscribed module
-- - b. respond RAI(SUCCESS) to mobile app
-- - c. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribed = true
local testModuleNumber = 2
local appSessionId = 1

--[[ Local Functions ]]
local function checkResumptionData()
  local expectedModules = common.getExpectedDataAllModules(testModuleNumber)
  common.checkResumptionData(#common.modules, expectedModules, true)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
for _, moduleType in pairs(common.modules) do
  common.Step("Add interiorVD subscription for " .. moduleType, common.GetInteriorVehicleData,
    { moduleType, common.getModuleId(moduleType, testModuleNumber), isSubscribed })
end

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Re-register App resumption data", common.reRegisterApp,
  { appSessionId, checkResumptionData, common.resumptionFullHMILevel })
for _, moduleType in pairs(common.modules) do
  common.Step("Check subscription with OnInteriorVD " .. moduleType, common.onInteriorVD,
    { moduleType, common.getModuleId(moduleType, testModuleNumber) })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
