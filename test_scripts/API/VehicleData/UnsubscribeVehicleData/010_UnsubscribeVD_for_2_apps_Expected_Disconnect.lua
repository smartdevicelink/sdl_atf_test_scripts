---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2283
--
-- Description: Check that SDL processes UnsubscribeVehicleData RPC for two Apps with <vd_param> parameters
--  during an unregistration of App
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Two apps are registered and activated
-- 3) SubscribeVehicleData, UnsubscribeVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 4) Apps are subscribed to <vd_param> parameter data
--
-- In case:
-- 1) App_1 sends UnregisterAppInterface request to SDL
-- SDL does:
-- a) not send UnsubscribeVehicleData request to HMI during the unregistration of App1
-- 2) App_2 sends UnregisterAppInterface request to SDL
-- SDL does:
-- a) send UnsubscribeVehicleData request to HMI during the unregistration of App2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

common.runner.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.runner.Step("Register App_1", common.registerApp, { common.app[1] })
  common.runner.Step("Register App_2", common.registerAppWOPTU, { common.app[2] })
  common.runner.Title("VD parameters: " .. param)
  common.runner.Step("App1 subscribes to VD " .. param,
    common.processSubscriptionRPC, { common.rpc.sub, param, common.app[1], common.isExpectedSubscription })
  common.runner.Step("App2 subscribes to VD " .. param,
    common.processSubscriptionRPC, { common.rpc.sub, param, common.app[2], common.isNotExpectedSubscription })
  common.runner.Step("OnVehicleData for both apps", common.sendOnVehicleDataTwoApps,
    { param, common.isExpected, common.isExpected })
  common.runner.Step("Unregister App1 without unsubscribes from VD " .. param,
    common.unregisterAppWithUnsubscription, { param, common.app[1], common.isNotExpectedSubscription })
  common.runner.Step("OnVehicleData for both apps", common.sendOnVehicleDataTwoApps,
    { param, common.isNotExpected, common.isExpected })
  common.runner.Step("Unregister App2 with unsubscribes from VD " .. param,
    common.unregisterAppWithUnsubscription, { param, common.app[2], common.isExpectedSubscription })
  common.runner.Step("OnVehicleData for both apps", common.sendOnVehicleDataTwoApps,
    { param, common.isNotExpected, common.isNotExpected })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
