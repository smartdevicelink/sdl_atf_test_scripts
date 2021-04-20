---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL sends OnHashChange notification after successful subscription to interior vehicle data
--  without moduleId
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is not subscribed to moduleType_1
--
-- Sequence:
-- 1. GetInteriorVehicleData(subscribe = true, moduleType_1) is requested
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(subscribe = true, moduleType_1, default moduleId) request to HMI
-- 2. HMI sends successful RC.GetInteriorVehicleData(moduleType_1, default moduleId, isSubscribed = true)
--  response to SDL
-- SDL does:
-- - a. send OnHashChange notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local moduleId = nil

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for _, moduleName in pairs(common.modules)do
  common.Step("OnHashChange after adding subscription to " .. moduleName, common.GetInteriorVehicleData,
    { moduleName, moduleId, common.IVDataSubscribeAction.subscribe, common.IVDataCacheState.isNotCached,
      common.onHashChangeTimes.expect })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
