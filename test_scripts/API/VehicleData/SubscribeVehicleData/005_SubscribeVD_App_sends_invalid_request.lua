---------------------------------------------------------------------------------------------------
-- Description: Check that SDL responds with resultCode "INVALID_DATA" to SubscribeVehicleData request
-- if App sends request with invalid data for <vd_param> parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData RPC and <vd_param> parameter are allowed by policies
-- 3) App is registered
--
-- In case:
-- 1) App sends invalid SubscribeVehicleData(<vd_param>=123) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = "INVALID_DATA") to App
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
  common.runner.Step("RPC " .. common.rpc.sub .. " invalid App request",
    common.processRPCFailure, { common.rpc.sub, param, result, value })
end

common.runner.Title("Postconditions")
common.runner.Step("Stop SDL", common.postconditions)
