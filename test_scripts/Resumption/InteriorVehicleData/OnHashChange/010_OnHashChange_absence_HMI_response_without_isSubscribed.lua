---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL does not send OnHashChange notification to mobile app in case HMI responds with successful response
--  but without isSubscribed parameter
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is not subscribed to module_1
--
-- Sequence:
-- 1. GetInteriorVehicleData(module_1, subscribe = true) is requested
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(module_1, subscribe = true) request to HMI
-- 2. HMI sends RC.GetInteriorVehicleData(SUCCESS, without isSubscribed)
-- SDL does:
-- - a. process successful responses from HMI
-- - b. not send OnHashChange notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribedReq = true
local isSubscribedRes = nil

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for _, moduleName in pairs(common.modules)do
  common.Step("Absence OnHashChange after GetInteriorVD without subscribe to " .. moduleName,
    common.getIVDCustomSubscribe, { moduleName, isSubscribedReq, isSubscribedRes })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
