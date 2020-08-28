---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: Successful resuming of interior vehicle data after transport disconnect
--  in case app was subscribed to all default modules (without moduleId)
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to all default modules via GetInteriorVehicleData(moduleType)
--
-- Sequence:
-- 1. Transport disconnect and reconnect are performed
-- 2. App starts registration with actual hashId after unexpected disconnect
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(subscribe=true, moduleType, default_moduleId) to HMI during resumption data
--    for each default module
-- 3. HMI sends successful RC.GetInteriorVehicleData(isSubscribed = true) response for each default module to SDL
-- SDL does:
-- - a. respond RAI(success=true, result code = SUCCESS) to mobile app
-- - b. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local moduleId = nil
local appSessionId = 1

--[[ Local Functions ]]
local function checkResumptionData()
  local expectedModules = common.getExpectedDataAllModules()
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
    { moduleType, moduleId, common.IVDataSubscribeAction.subscribe })
end

common.Title("Test")
common.Step("Unexpected disconnect", common.mobileDisconnect)
common.Step("Connect mobile", common.mobileConnect)
common.Step("Re-register App resumption data", common.reRegisterApp,
  { appSessionId, checkResumptionData, common.resumptionFullHMILevel })
for _, moduleType in pairs(common.modules) do
  common.Step("Check subscription with OnInteriorVD " .. moduleType, common.onInteriorVD, { moduleType })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
