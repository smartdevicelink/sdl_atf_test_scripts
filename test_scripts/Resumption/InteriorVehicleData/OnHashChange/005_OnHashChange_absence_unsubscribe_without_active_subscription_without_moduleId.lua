---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL does not send OnHashChange notification to mobile app in case processing
--  of GetInteriorVehicleData(subscribe=false) without active subscription without moduleId
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is not subscribed to moduleType_1
--
-- Sequence:
-- 1. GetInteriorVehicleData(subscribe = false, moduleType_1) is requested
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(subscribe = false, moduleType_1, default moduleId) request to HMI
-- 2. HMI sends successful RC.GetInteriorVehicleData(moduleType_1, default moduleId, isSubscribed = false)
--  response to SDL
-- SDL does:
-- - a. not send OnHashChange notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local withoutModuleId = nil
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
    common.GetInteriorVehicleData, { moduleName, withoutModuleId, isNotSubscribed, isNotCached, notExpectNotif })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
