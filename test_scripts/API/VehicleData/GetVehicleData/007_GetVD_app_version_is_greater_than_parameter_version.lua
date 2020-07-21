---------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes vehicle data RPCs with <vd_param> parameter
-- if an app is registered with version greater than current parameter version
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Vehicle Data RPCs and <vd_param> parameter are allowed by policies
-- 3) <vd_param> parameter has param_version defined (e.g. 5.1.0)
-- 4) App is registered with specific syncMsgVersion (e.g. 5.1.1)
--  which is greater than version of <vd_param> parameter
--
-- In case:
-- 1) App sends any of Vehicle Data RPC with <vd_param> parameter
-- - a) GetVehicleData, SubscribeVehicleData, UnsubscribeVehicleData
-- SDL does:
-- - a) process this RPC successfully
-- 2) App is subscribed to <vd_param> parameter
-- 3) HMI sends OnVehicleData notification with <vd_param> parameter
-- SDL does:
-- - a) process this Notification successfully
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Scenario ]]
for param, version in common.spairs(common.versioningVD) do
  common.Title("VD parameter: " .. param)
  common.Title("Preconditions")
  common.Step("Clean environment and update preloaded_pt file", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Set App version", common.setAppVersion, { version, common.operator.increase })
  common.Step("Register App", common.registerApp)

  common.Title("Test")
  common.Step("RPC " .. common.rpc.get, common.getVehicleData, { param })
  common.Step("RPC " .. common.rpc.sub, common.processSubscriptionRPC, { common.rpc.sub, param })
  common.Step("RPC " .. common.rpc.on, common.sendOnVehicleData, { param, common.isExpected })
  common.Step("RPC " .. common.rpc.unsub, common.processSubscriptionRPC, { common.rpc.unsub, param })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
