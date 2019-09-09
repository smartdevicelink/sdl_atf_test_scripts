---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case: request is allowed by Policies
--
-- Requirement summary:
-- [SubscribeVehicleData] As a mobile app wants to send a request to subscribe for specified parameter
--
-- Description:
-- In case:
-- 1) mobile application sends valid SubscribeVehicleData to SDL and this request is allowed by Policies
-- SDL must:
-- Transfer this request to HMI and after successful response from hmi
-- Respond SUCCESS, success:true to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
-- removed because vin parameter is not applicable for SubscribeVehicleData
common.allVehicleData.vin = nil

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
for vehicleDataName in pairs(common.allVehicleData) do
  runner.Step("RPC " .. rpc .. " " .. vehicleDataName, common.processRPCSubscriptionSuccess,
    {rpc, vehicleDataName })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
