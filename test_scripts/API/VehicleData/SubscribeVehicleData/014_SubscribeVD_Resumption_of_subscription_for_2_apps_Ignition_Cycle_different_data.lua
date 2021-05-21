---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2283
--
-- Description: Check that SDL resumes the subscription for different <vd_param> parameter for two Apps
-- after Ignition Cycle
--
-- Precondition:
-- 1) Two apps are registered and activated
-- 2) App_1 is subscribed to <vd_param_1> parameter
-- 3) App_2 is subscribed to <vd_param_2> parameter
-- 4) Ignition cycle is performed
--
-- In case:
-- 1) App_1 registers with actual hashID
-- SDL does:
--  a) start data resumption for App_1
--  b) start to resume the subscription and sends VI.SubscribeVehicleData request to HMI
--  c) after success response from HMI SDL resumes the subscription
-- 2) App_2 registers with actual hashID
-- SDL does:
--  a) start data resumption for App_2
--  b) start to resume the subscription and sends VI.SubscribeVehicleData request to HMI
-- 3) HMI sends OnVehicleData notification with <vd_param_1> parameter
-- SDL does:
--  a) resend OnVehicleData notification to mobile App_1
-- 4) HMI sends OnVehicleData notification with <vd_param_2> parameter
-- SDL does:
--  a) resend OnVehicleData notification to mobile App_2
--------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Conditions to skip test ]]
if #common.restrictedVDParams == 1 then
  common.runner.skipTest("Test is not applicable for one restricted VD parameter")
end

--[[ Scenario ]]
for param1 in common.spairs(common.getVDParams(true)) do
  local param2 = common.getAnotherSubVDParam(param1)
  common.runner.Title("VD parameters: " .. param1 .. ", " .. param2)
  common.runner.Title("Preconditions")
  common.runner.Step("Clean environment", common.preconditions)
  common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.runner.Step("Register App1", common.registerAppWOPTU, { common.app[1] })
  common.runner.Step("Register App2", common.registerAppWOPTU, { common.app[2] })
  common.runner.Step("App1 subscribes to VD " .. param1, common.processSubscriptionRPC,
    { common.rpc.sub, param1, common.app[1], common.isExpectedSubscription })
  common.runner.Step("App1 subscribes to VD " .. param2, common.processSubscriptionRPC,
    { common.rpc.sub, param2, common.app[2], common.isExpectedSubscription })

  common.runner.Title("Test")
  common.runner.Step("Ignition Off", common.ignitionOff, { param1, param2 })
  common.runner.Step("Ignition On", common.start)
  common.runner.Step("Re-register App1 resumption data", common.registerAppWithResumption,
    { param1, common.app[1], common.isExpectedSubscription })
  common.runner.Step("Re-register App2 resumption data", common.registerAppWithResumption,
    { param2, common.app[2], common.isExpectedSubscription })
  common.runner.Step("OnVehicleData for App_1", common.sendOnVehicleDataTwoApps,
    { param1, common.isExpected, common.isNotExpected })
  common.runner.Step("OnVehicleData for App_2", common.sendOnVehicleDataTwoApps,
    { param2, common.isNotExpected, common.isExpected })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
