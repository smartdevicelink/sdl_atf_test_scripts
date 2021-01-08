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
for _, test in common.spairs(common.getTests(common.rpc.get, common.testType.PARAM_VERSION)) do
  common.runner.Title("VD parameter: " .. test.param)
  common.runner.Title("Preconditions")
  common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
  common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.runner.Step("Set App version", common.setAppVersion, { test.version, common.operator.decrease })
  common.runner.Step("Register App", common.registerApp)

  common.runner.Title("Test")
  common.runner.Step("RPC " .. common.rpc.get, common.processRPCFailure, { common.rpc.get, test.param, result })
  common.runner.Step("RPC " .. common.rpc.sub, common.processRPCFailure, { common.rpc.sub, test.param, result })
  common.runner.Step("RPC " .. common.rpc.on, common.sendOnVehicleData, { test.param, common.isNotExpected })
  common.runner.Step("RPC " .. common.rpc.unsub, common.processRPCFailure, { common.rpc.unsub, test.param, result })

  common.runner.Title("Postconditions")
  common.runner.Step("Stop SDL", common.postconditions)
end
