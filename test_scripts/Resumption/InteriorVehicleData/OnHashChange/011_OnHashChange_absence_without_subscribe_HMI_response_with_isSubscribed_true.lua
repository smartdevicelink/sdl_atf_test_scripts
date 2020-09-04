---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description: SDL does not send OnHashChange notification to mobile app in case HMI responds
--  with successful response but with isSubscribed = true on GetInteriorVehicleData request
--  without subscribe parameter
--
-- Precondition:
-- 1. HMI and SDL are started
-- 2. Mobile app with REMOTE_CONTROL hmi type is registered and activated
-- 3. App is not subscribed to module_1
--
-- Sequence:
-- 1. GetInteriorVehicleData(module_1) is requested
-- SDL does:
-- - a. send RC.GetInteriorVehicleData(module_1) request to HMI
-- 2. HMI sends RC.GetInteriorVehicleData(SUCCESS, isSubscribed = true)
-- SDL does:
-- - a. process successful responses from HMI
-- - b. not send OnHashChange notification to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Resumption/InteriorVehicleData/commonResumptionsInteriorVD')

--[[ Local Variables ]]
local isSubscribedReq = nil
local isSubscribedRes = true

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for _, moduleName in pairs(common.modules)do
  common.Step("Absence OnHashChange after GetInteriorVD(isSubscribed=true) response to " .. moduleName,
    common.getIVDCustomSubscribe, { moduleName, isSubscribedReq, isSubscribedRes })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
