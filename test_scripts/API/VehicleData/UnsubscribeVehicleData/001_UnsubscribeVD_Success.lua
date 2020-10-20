---------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes UnsubscribeVehicleData RPC with <vd_param> parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, UnsubscribeVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 3) App is registered
-- 4) App is subscribed to <vd_param> parameter
--
-- In case:
-- 1) App sends valid UnsubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends VI.UnsubscribeVehicleData response with <vd_param> parameter to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
--    <vd_param> = <data received from HMI>) to App
-- Exception: SDL does respond with "INVALID_DATA" in case app tries to unsubscribe from unsubscribable VD parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.Title("VD parameter: " .. param)
  common.Step("RPC " .. common.rpc.sub, common.processSubscriptionRPC, { common.rpc.sub, param })
  common.Step("RPC " .. common.rpc.unsub, common.processSubscriptionRPC, { common.rpc.unsub, param })
end

for param in common.spairs(common.getVDParams(false)) do
  common.Title("VD parameter: " .. param)
  common.Step("RPC " .. common.rpc.unsub .. " INVALID_DATA", common.processRPCFailure,
    { common.rpc.unsub, param, "INVALID_DATA" })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
