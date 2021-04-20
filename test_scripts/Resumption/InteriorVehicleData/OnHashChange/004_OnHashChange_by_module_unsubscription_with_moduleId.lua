---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL sends OnHashChange notification after successful unsubscription from interior vehicle data
--  with specified moduleId
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to moduleType_1
--
-- Sequence:
-- 1. GetInteriorVehicleData(subscribe = false, moduleType_1, moduleId) is requested
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(subscribe = false, moduleType_1, moduleId) request to HMI
-- 2. HMI sends successful RC.GetInteriorVehicleData(moduleType_1, moduleId, isSubscribed = false) response to SDL
-- SDL does:
-- - a. send OnHashChange notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for _, moduleName in pairs(common.modules)do
  local moduleId = common.getModuleId(moduleName, 2)
  common.Step("Subscription to " .. moduleName, common.GetInteriorVehicleData,
    { moduleName, moduleId, common.IVDataSubscribeAction.subscribe, common.IVDataCacheState.isNotCached,
      common.onHashChangeTimes.expect })
  common.Step("OnHashChange after removing subscription for " .. moduleName, common.GetInteriorVehicleData,
    { moduleName, moduleId, common.IVDataSubscribeAction.unsubscribe, common.IVDataCacheState.isNotCached,
      common.onHashChangeTimes.expect })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
