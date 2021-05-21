---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2283
--
-- Description: Check that SDL processes UnsubscribeVehicleData RPC for two Apps with different <vd_param> parameters
--  during an unregistration of App
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Two apps are registered and activated
-- 3) SubscribeVehicleData, UnsubscribeVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 4) App_1 is subscribed to <vd_param_1> parameter
-- 5) App_2 is subscribed to <vd_param_2> parameter
--
-- In case:
-- 1) App_1 sends UnregisterAppInterface request to SDL
-- SDL does:
-- a) send UnsubscribeVehicleData request with <vd_param_1> to HMI during the unregistration of App1
-- 2) App_2 sends UnregisterAppInterface request to SDL
-- SDL does:
-- a) send UnsubscribeVehicleData request with <vd_param_2> to HMI during the unregistration of App2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Conditions to skip test ]]
if #common.restrictedVDParams == 1 then
  common.runner.skipTest("Test is not applicable for one restricted VD parameter")
end

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

common.runner.Title("Test")
for param1 in common.spairs(common.getVDParams(true)) do
  local param2 = common.getAnotherSubVDParam(param1)
  common.runner.Step("Register App_1", common.registerApp, { common.app[1] })
  common.runner.Step("Register App_2", common.registerAppWOPTU, { common.app[2] })
  common.runner.Title("VD parameters: " .. param1 .. ", " .. param2)
  common.runner.Step("App1 subscribes to VD " .. param1,
    common.processSubscriptionRPC, { common.rpc.sub, param1, common.app[1], common.isExpectedSubscription })
  common.runner.Step("App2 subscribes to VD " .. param2,
    common.processSubscriptionRPC, { common.rpc.sub, param2, common.app[2], common.isExpectedSubscription })
  common.runner.Step("OnVehicleData for App_1", common.sendOnVehicleDataTwoApps,
    { param1, common.isExpected, common.isNotExpected })
  common.runner.Step("OnVehicleData for App_2", common.sendOnVehicleDataTwoApps,
    { param2, common.isNotExpected, common.isExpected })
  common.runner.Step("Unregister App1 with unsubscribes from VD " .. param1,
    common.unregisterAppWithUnsubscription, { param1, common.app[1], common.isExpectedSubscription })
  common.runner.Step("Absence of OnVehicleData for App_1", common.sendOnVehicleDataTwoApps,
    { param1, common.isNotExpected, common.isNotExpected })
  common.runner.Step("OnVehicleData for App_2", common.sendOnVehicleDataTwoApps,
    { param2, common.isNotExpected, common.isExpected })
  common.runner.Step("Unregister App2 with unsubscribes from VD " .. param2,
    common.unregisterAppWithUnsubscription, { param2, common.app[2], common.isExpectedSubscription })
  common.runner.Step("Absence of OnVehicleData for App_1", common.sendOnVehicleDataTwoApps,
    { param1, common.isNotExpected, common.isNotExpected })
  common.runner.Step("Absence of OnVehicleData for App_2", common.sendOnVehicleDataTwoApps,
    { param2, common.isNotExpected, common.isNotExpected })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
