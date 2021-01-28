---------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "INVALID_DATA" to UnsubscribeVehicleData request
-- if App sends request with invalid data for <vd_param> parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, UnsubscribeVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 3) App is registered and subscribed to <vd_param> parameter
--
-- In case:
-- 1) App sends invalid UnsubscribeVehicleData(<vd_param>=123) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = "INVALID_DATA") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local result = "INVALID_DATA"
local value = 123

--[[ Scenario ]]
common.runner.Title("Preconditions")
common.runner.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.runner.Step("Register App", common.registerApp)

common.runner.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.runner.Title("VD parameter: " .. param)
  common.runner.Step("RPC " .. common.rpc.sub .. " SUCCESS", common.processSubscriptionRPC,
    { common.rpc.sub, param })
  common.runner.Step("RPC " .. common.rpc.unsub .. " invalid App request",
    common.processRPCFailure, { common.rpc.unsub, param, result, value })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
