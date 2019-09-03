---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case: request is allowed by Policies
--
-- Requirement summary:
-- [UnsubscribeVehicleData] Mobile app wants to send a request to unsubscribe
--  for already subscribed specified parameter
--
-- Description:
-- In case:
-- Mobile application sends valid UnsubscribeVehicleData to SDL
-- This request is allowed by Policies and mobile app is subscribed for this parameter
-- SDL must:
-- Transfer this request to HMI and after successful response from hmi
-- Respond SUCCESS, success:true to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc_subscribe = "SubscribeVehicleData"
local rpc_unsubscribe = "UnsubscribeVehicleData"
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
  runner.Step("RPC " .. rpc_subscribe .. " " .. vehicleDataName, common.processRPCSubscriptionSuccess,
    {rpc_subscribe, vehicleDataName })
  runner.Step("RPC " .. rpc_unsubscribe .. " " .. vehicleDataName, common.processRPCSubscriptionSuccess,
    {rpc_unsubscribe, vehicleDataName })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
