---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL does not send OnHashChange notification to mobile app in case processing
--  of GetInteriorVehicleData(subscribe=false) without active subscription with specified moduleId
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is not subscribed to module_1
--
-- Sequence:
-- 1. GetInteriorVehicleData(subscribe = false, module_1, moduleId) is requested
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(subscribe = false, module_1, moduleId) request to HMI
-- - b. process successful responses from HMI
-- - c. not send OnHashChange notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local notExpectNotif = 0
local isNotSubscribed = false
local isNotCached = false

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for _, moduleName in pairs(common.modules)do
  common.Step("Absence OnHashChange after GetInteriorVD(subscribe=false) to " .. moduleName,
    common.GetInteriorVehicleData,
    { moduleName, common.getModuleId(moduleName, 2), isNotSubscribed, isNotCached, notExpectNotif })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
