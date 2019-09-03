---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case 1: Main Flow
-- Item: Use Case: request is allowed by Policies
--
-- Requirement summary:
-- [OnVehicleData] As a hmi sends notification about VI parameter change
--  but mobile app is not subscribed for this parameter
--
-- Description:
-- In case:
-- 1) Hmi sends valid OnVehicleData notification to SDL
--    but mobile app is not subscribed for this parameter
-- SDL must:
-- Ignore this request and do not forward it to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc1 = "SubscribeVehicleData"
local rpc2 = "UnsubscribeVehicleData"
-- removed because vin parameter is not applicable for SubscribeVehicleData
common.allVehicleData.vin = nil

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for vehicleDataName in pairs(common.allVehicleData) do
  runner.Step("RPC " .. rpc1 .. " " .. vehicleDataName, common.processRPCSubscriptionSuccess,
    {rpc1, vehicleDataName })
  runner.Step("RPC OnVehicleData " .. vehicleDataName .. " forwarded to mobile", common.checkNotificationSuccess,
    { vehicleDataName })
  runner.Step("RPC " .. rpc2 .. " " .. vehicleDataName, common.processRPCSubscriptionSuccess,
    {rpc2, vehicleDataName })
  runner.Step("RPC OnVehicleData " .. vehicleDataName .. " not forwarded to mobile", common.checkNotificationIgnored,
    { vehicleDataName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
