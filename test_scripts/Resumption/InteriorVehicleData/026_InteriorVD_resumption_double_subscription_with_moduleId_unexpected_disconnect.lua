---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL sends GetInteriorVehicleData response with WARNINGS result code
--  in case of double subscription with specified moduleId after successful resuming on transport disconnect
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to all modules via GetInteriorVehicleData(moduleType, moduleId)
-- 4. Unexpected disconnect and reconnect are performed
-- 5. App reregisters with actual HashId after unexpected disconnect
-- 6. HMI responds with SUCCESS resultCode to all requests from SDL
--
-- Sequence:
-- 1. GetInteriorVehicleData(subscribe = true, moduleType_1, moduleId) is requested from App
-- SDL does:
-- - a. not send RC.GetInteriorVehicleData(subscribe=true, moduleType_1, default moduleId) request to HMI
-- - b. send GetInteriorVehicleData response (success=true, resultCode=WARNINGS, isSubscribed=true )
--    response to mobile App
-- - c. not send OnHashChange notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local appSessionId = 1

--[[ Local Functions ]]
local function checkResumptionData()
  local testModuleNumber = 2
  local expectedModules = common.getExpectedDataAllModules(testModuleNumber)
  common.checkResumptionData(#common.modules, expectedModules, true)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
for _, moduleType in pairs(common.modules)do
  common.Step("Subscription to " .. moduleType, common.GetInteriorVehicleData,
    { moduleType, common.getModuleId(moduleType, 2), common.IVDataSubscribeAction.subscribe,
      common.IVDataCacheState.isNotCached, common.onHashChangeTimes.expect })
end
common.Step("Unexpected disconnect", common.mobileDisconnect)
common.Step("Connect mobile", common.mobileConnect)
common.Step("Re-register App resumption data", common.reRegisterApp,
  { appSessionId, checkResumptionData, common.resumptionFullHMILevel })

common.Title("Test")
for _, moduleType in pairs(common.modules)do
  common.Step("Second subscription to " .. moduleType , common.GetInteriorVehicleData,
    { moduleType, common.getModuleId(moduleType, 2), common.IVDataSubscribeAction.subscribe,
      common.IVDataCacheState.isCached, common.onHashChangeTimes.notExpect, appSessionId, "WARNINGS" })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
