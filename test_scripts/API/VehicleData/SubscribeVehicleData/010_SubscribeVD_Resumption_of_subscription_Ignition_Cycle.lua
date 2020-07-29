---------------------------------------------------------------------------------------------------
-- Description: Check that SDL resumes the subscription for <vd_param> parameter after Ignition Cycle
--
-- In case:
-- 1) App is subscribed to <vd_param> parameter
-- 2) Ignition cycle is performed
-- 3) App re-registered with actual HashId
-- SDL does:
--  a) send SubscribeVehicleData(<vd_param>=true) request to HMI
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
  common.Title("VD parameter: " .. param)
  common.Title("Preconditions")
  common.Step("Clean environment and update preloaded_pt file", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Register App", common.registerApp)
  common.Step("App subscribes to VD param", common.processSubscriptionRPC,
    { common.rpc.sub, param })

  common.Title("Test")
  common.Step("Ignition Off", common.ignitionOff, { param })
  common.Step("Ignition On", common.start)
  common.Step("Re-register App resumption data", common.registerAppWithResumption,
    { param, common.app[1], common.isExpectedSubscription })
  common.Step("OnVehicleData with VD param", common.sendOnVehicleData, { param, common.isExpected })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
