---------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes UnsubscribeVehicleData RPC for two Apps with <vd_param> parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, UnsubscribeVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 3) App_1 and App_2 are registered and subscribed to <vd_param> data
--
-- In case:
-- 1) App_1 sends valid UnsubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
--    <vd_param> = <data received from HMI>) to App_1
-- - b) not transfer this request to HMI
-- 2) App_2 sends valid UnsubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 3) HMI sends VI.UnsubscribeVehicleData response with <vd_param> data to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
--    <vd_param> = <data received from HMI>) to App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("Register App_1", common.registerApp, { common.app[1] })
common.runner.Step("Register App_2", common.registerAppWOPTU, { common.app[2] })

common.runner.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.runner.Title("VD parameter: " .. param)
  common.runner.Step("RPC " .. common.rpc.sub .. " for App_1",
    common.processSubscriptionRPC, { common.rpc.sub, param, common.app[1], common.isExpectedSubscription })
  common.runner.Step("RPC " .. common.rpc.sub .. " for App_2",
    common.processSubscriptionRPC, { common.rpc.sub, param, common.app[2], common.isNotExpectedSubscription })
  common.runner.Step("OnVehicleData for both apps",
    common.sendOnVehicleDataTwoApps, { param, common.isExpected, common.isExpected })
  common.runner.Step("RPC " .. common.rpc.unsub .. " for App_1",
    common.processSubscriptionRPC, { common.rpc.unsub, param, common.app[1], common.isNotExpectedSubscription })
  common.runner.Step("Absence of OnVehicleData for App_1",
    common.sendOnVehicleDataTwoApps, { param, common.isNotExpected, common.isExpected })
  common.runner.Step("RPC " .. common.rpc.unsub .. " for App_2",
    common.processSubscriptionRPC, { common.rpc.unsub, param, common.app[2], common.isExpectedSubscription })
  common.runner.Step("Absence of OnVehicleData for both apps",
    common.sendOnVehicleDataTwoApps, { param, common.isNotExpected, common.isNotExpected })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
