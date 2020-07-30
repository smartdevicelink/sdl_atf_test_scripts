---------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "IGNORED" to 2nd SubscribeVehicleData request
-- with <vd_param> prameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData RPC and <vd_param> parameter are allowed by policies
-- 3) App is registered
--
-- In case:
-- 1) App sends valid SubscribeVehicleData(<vd_param>=true) request to SDL
-- SDL does:
-- - a) process request successfully
-- 2) App sends valid SubscribeVehicleData(<vd_param>=true) request to SDL 2nd time
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = "IGNORED") to App
-- - b) not transfer this request to HMI
-- Exception: SDL does respond with "INVALID_DATA" in case app tries to subscribe for unsubscribable VD parameter
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
  common.Step("RPC 1 " .. common.rpc.sub .. " SUCCESS", common.processSubscriptionRPC,
    { common.rpc.sub, param })
  common.Step("RPC 2 " .. common.rpc.sub .. " IGNORED", common.processRPCFailure,
    { common.rpc.sub, param, result })
end
for param in common.spairs(common.getVDParams(false)) do
  common.Title("VD parameter: " .. param)
  common.Step("RPC 1 " .. common.rpc.sub .. " INVALID_DATA", common.processRPCFailure,
    { common.rpc.sub, param, "INVALID_DATA" })
  common.Step("RPC 2 " .. common.rpc.sub .. " INVALID_DATA", common.processRPCFailure,
    { common.rpc.sub, param, "INVALID_DATA" })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
