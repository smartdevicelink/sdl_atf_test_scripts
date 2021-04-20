---------------------------------------------------------------------------------------------------
-- Description: Check that SDL resumes the subscription for <vd_param> parameter after unexpected disconnect
--
-- In case:
-- 1) App is subscribed to <vd_param> parameter
-- 2) Unexpected disconnect and reconnect are performed
-- 3) App re-registered with actual HashId
-- SDL does:
--  a) send VI.SubscribeVehicleData(<vd_param>=true) request to HMI
-- 4) HMI sends SubscribeVehicleData response to SDL
-- SDL does:
--  a) not send SubscribeVehicleData response to mobile app
-- 5) HMI sends valid OnVehicleData notification with <vd_param> parameter data.
-- SDL does:
--  a) process this notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Scenario ]]
for param in common.spairs(common.getVDParams(true)) do
  common.runner.Title("VD parameter: " .. param)
  common.runner.Title("Preconditions")
  common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
  common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.runner.Step("Register App", common.registerApp)
  common.runner.Step("App subscribes to VD param", common.processSubscriptionRPC,
    { common.rpc.sub, param })

  common.runner.Title("Test")
  common.runner.Step("Unexpected disconnect", common.unexpectedDisconnect, { param })
  common.runner.Step("Connect mobile", common.connectMobile)
  common.runner.Step("Re-register App resumption data", common.registerAppWithResumption,
    { param, common.app[1], common.isExpectedSubscription })
  common.runner.Step("OnVehicleData with VD param", common.sendOnVehicleData, { param, common.isExpected })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
