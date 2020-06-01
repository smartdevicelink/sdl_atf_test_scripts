---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case: request is allowed by Policies
--
-- Requirement summary:
-- [UnsubscribeVehicleData] Mobile app wants to send a request to unsubscribe
--  for already subscribed specified parameter
--
-- Description: SDL sends VI.UnsubscribeVehicleData request to HMI during an unsubscription of last subscribed app
--
-- In case:
-- 1) App1 and App2 are registered and activated
-- 1) App1 is subscribed to vehicle data_1
-- 2) App2 is subscribed to vehicle data_1
-- 3) App2 sends valid UnsubscribeVehicleData(data_1) to SDL and this request is allowed by Policies
-- SDL does:
-- a) not transfer this request to HMI
-- b) respond with resultCode:SUCCESS, success:true to App2
-- c) remove the subscription internally
-- 4) App1 sends valid UnsubscribeVehicleData(data_1) to SDL and this request is allowed by Policies
-- SDL does:
-- a) send VI.SubscribeVehicleData request to HMI
-- b) remove the subscription after a receiving of the response from HMI
-- c) respond with resultCode:SUCCESS, success:true to App1
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local appId1 = 1
local appId2 = 2
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local isExpectedSubscribeVDonHMI = true
local isNotExpectedSubscribeVDonHMI = false
local vehicleData = "fuelRange"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerAppWOPTU, { appId1 })
runner.Step("Register App2", common.registerApp, { appId2 })
runner.Step("PTU", common.policyTableUpdate, { common.ptUpdateForApp2AndNotifLevel })
runner.Step("Activate App1", common.activateApp, { appId1 })
runner.Step("Activate App2", common.activateApp, { appId2 })

runner.Title("Test")
runner.Step("App1 subscribes to fuelRange", common.processRPCSubscriptionSuccess,
  { rpc_sub, vehicleData, appId1, isExpectedSubscribeVDonHMI })
runner.Step("App2 subscribes to fuelRange", common.processRPCSubscriptionSuccess,
  { rpc_sub, vehicleData, appId2, isNotExpectedSubscribeVDonHMI })
runner.Step("OnVehicleData to both apps", common.checkNotificationSuccess2Apps, { vehicleData })
runner.Step("App2 unsubscribes from fuelRange", common.processRPCSubscriptionSuccess,
  { rpc_unsub, vehicleData, appId2, isNotExpectedSubscribeVDonHMI })
runner.Step("App1 unsubscribes from fuelRange", common.processRPCSubscriptionSuccess,
  { rpc_unsub, vehicleData, appId1, isExpectedSubscribeVDonHMI })
runner.Step("Absence OnVehicleData for both apps", common.checkNotificationIgnored2Apps, { vehicleData })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
