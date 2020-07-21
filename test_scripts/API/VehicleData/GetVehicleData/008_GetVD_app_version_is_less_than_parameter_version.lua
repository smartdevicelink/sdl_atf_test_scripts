---------------------------------------------------------------------------------------------------
-- Description: Check that SDL rejects vehicle data RPCs with <vd_param> parameter
-- if an app is registered with version less than current parameter version
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Vehicle Data RPCs and <vd_param> parameter are allowed by policies
-- 3) <vd_param> parameter has param_version defined (e.g. 5.1.0)
-- 4) App is registered with specific syncMsgVersion (e.g. 5.0.9)
--  which is less than version of <vd_param> parameter
--
-- In case:
-- 1) App sends any of Vehicle Data RPC with <vd_param> parameter
-- - a) GetVehicleData, SubscribeVehicleData, UnsubscribeVehicleData
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = "INVALID_DATA") to App
-- - b) not transfer this request to HMI
-- 2) HMI sends OnVehicleData notification with <vd_param> parameter
-- SDL does:
-- - a) ignore this notification and not transfer it to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local result = "INVALID_DATA"

--[[ Scenario ]]
for param, version in common.spairs(common.versioningVD) do
  common.Title("VD parameter: " .. param)
  common.Title("Preconditions")
  common.Step("Clean environment and update preloaded_pt file", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Set App version", common.setAppVersion, { version, common.operator.decrease })
  common.Step("Register App", common.registerApp)

  common.Title("Test")
  common.Step("RPC " .. common.rpc.get, common.processRPCFailure, { common.rpc.get, param, result })
  common.Step("RPC " .. common.rpc.sub, common.processRPCFailure, { common.rpc.sub, param, result })
  common.Step("RPC " .. common.rpc.on, common.sendOnVehicleData, { param, common.isNotExpected })
  common.Step("RPC " .. common.rpc.unsub, common.processRPCFailure, { common.rpc.unsub, param, result })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
