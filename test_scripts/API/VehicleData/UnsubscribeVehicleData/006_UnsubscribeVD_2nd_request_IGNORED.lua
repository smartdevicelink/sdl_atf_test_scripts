---------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "IGNORED" to 2nd UnsubscribeVehicleData request
-- with <vd_param> prameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, UnsubscribeVehicleData RPC and <vd_param> parameter are allowed by policies
-- 3) App is registered and subscribed to <vd_param> parameter
--
-- In case:
-- 1) App sends valid UnsubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) process request successfully
-- 2) App sends valid UnsubscribeVehicleData(<vd_param>=true) request to SDL 2nd time
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = "IGNORED") to App
-- - b) not transfer this request to HMI
-- Exception: SDL does respond with "INVALID_DATA" in case app tries to unsubscribe from unsubscribable VD parameter
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local result = "IGNORED"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.Title("VD parameter: " .. param)
  common.Step("RPC " .. common.rpc.sub .. " SUCCESS", common.processSubscriptionRPC,
    { common.rpc.sub, param })
  common.Step("RPC 1 " .. common.rpc.unsub .. " SUCCESS", common.processSubscriptionRPC,
    { common.rpc.unsub, param })
  common.Step("RPC 2 " .. common.rpc.unsub .. " IGNORED", common.processRPCFailure,
    { common.rpc.unsub, param, result })
end
for param in common.spairs(common.getVDParams(false)) do
  common.Title("VD parameter: " .. param)
  common.Step("RPC 1 " .. common.rpc.unsub .. " INVALID_DATA", common.processRPCFailure,
    { common.rpc.unsub, param, "INVALID_DATA" })
  common.Step("RPC 2 " .. common.rpc.unsub .. " INVALID_DATA", common.processRPCFailure,
    { common.rpc.unsub, param, "INVALID_DATA" })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
