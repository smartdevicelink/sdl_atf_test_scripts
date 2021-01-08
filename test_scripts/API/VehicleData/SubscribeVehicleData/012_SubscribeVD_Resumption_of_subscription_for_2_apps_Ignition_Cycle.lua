---------------------------------------------------------------------------------------------------
-- Description: Check that SDL resumes the subscription for <vd_param> parameter for two Apps
-- after Ignition Cycle
--
-- Precondition:
-- 1) Two apps are registered and activated
-- 2) Apps are subscribed to <vd_param> parameter data
-- 3) Ignition cycle is performed
--
-- In case:
-- 1) App_1 registers with actual hashID
-- SDL does:
--  a) start data resumption for app
--  b) start to resume the subscription and sends VI.SubscribeVehicleData request to HMI
--  c) after success response from HMI SDL resumes the subscription
-- 2) App_2 registers with actual hashID
-- SDL does:
--  a) start data resumption for app
--  b) resume the subscription internally and not send VI.SubscribeVehicleData request to HMI
-- 3) HMI sends OnVehicleData notification with <vd_param> parameter
-- SDL does:
--  a) resend OnVehicleData notification to both mobile apps
--------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Scenario ]]
for param in common.spairs(common.getVDParams(true)) do
  common.runner.Title("VD parameter: " .. param)
  common.runner.Title("Preconditions")
  common.runner.Step("Clean environment", common.preconditions)
  common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.runner.Step("Register App1", common.registerAppWOPTU, { common.app[1] })
  common.runner.Step("Register App2", common.registerAppWOPTU, { common.app[2] })
  common.runner.Step("App1 subscribes to VD param", common.processSubscriptionRPC,
    { common.rpc.sub, param, common.app[1], common.isExpectedSubscription })
  common.runner.Step("App2 subscribes to VD param", common.processSubscriptionRPC,
    { common.rpc.sub, param, common.app[2], common.isNotExpectedSubscription })

  common.runner.Title("Test")
  common.runner.Step("Ignition Off", common.ignitionOff, { param })
  common.runner.Step("Ignition On", common.start)
  common.runner.Step("Re-register App1 resumption data", common.registerAppWithResumption,
    { param, common.app[1], common.isExpectedSubscription })
  common.runner.Step("Re-register App2 resumption data", common.registerAppWithResumption,
    { param, common.app[2], common.isNotExpectedSubscription })
  common.runner.Step("OnVehicleData with VD param for both apps", common.sendOnVehicleDataTwoApps,
    { param, common.isExpected, common.isExpected })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
