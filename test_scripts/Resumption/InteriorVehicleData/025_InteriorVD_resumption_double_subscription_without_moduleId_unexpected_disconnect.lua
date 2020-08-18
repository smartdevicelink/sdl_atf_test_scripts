---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL sends GetInteriorVehicleData response with WARNINGS result code
--  in case of double subscription without moduleId after successful resuming on transport disconnect
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is subscribed to all modules via GetInteriorVehicleData(moduleType)
-- 4. Unexpected disconnect and reconnect are performed
-- 5. App reregisters with actual HashId after unexpected disconnect
-- 6. HMI responds with SUCCESS resultCode to all requests from SDL
--
-- Sequence:
-- 1. GetInteriorVehicleData(subscribe = true, module_1) is requested
-- SDL does:
-- - a. not send GetInteriorVehicleData request to HMI
-- - b. send GetInteriorVehicleData ("WARNINGS") response to mobile App
-- - c. not send OnHashChange notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local withoutModuleId = nil
local notExpectNotif = 0
local expectNotif = 1
local isSubscribed = true
local isCached = true
local isNotCached = false
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
for _, moduleType in pairs(common.modules)do
  common.Step("Add interiorVD subscription for " .. moduleType , common.GetInteriorVehicleData,
    { moduleType, withoutModuleId, isSubscribed, isNotCached, expectNotif, appSessionId })
end
common.Step("Unexpected disconnect", common.mobileDisconnect)
common.Step("Connect mobile", common.mobileConnect)
common.Step("Re-register App resumption data", common.reRegisterApp,
  { appSessionId, checkResumptionData, common.resumptionFullHMILevel })

common.Title("Test")
for _, moduleType in pairs(common.modules)do
  common.Step("Second subscription to " .. moduleType , common.GetInteriorVehicleData,
    { moduleType, withoutModuleId, isSubscribed, isCached, notExpectNotif, appSessionId, "WARNINGS" })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
