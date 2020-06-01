---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2282
--
-- Requirement summary:
-- [UnsubscribeVehicleData] Mobile app wants to send a request to unsubscribe
--  for already subscribed specified parameter
--
-- Description: SDL sends VI.UnsubscribeVehicleData request to HMI during an unregistration of last subscribed app
-- In case:
-- 1) App1 and App2 are registered and activated
-- 2) App1 is subscribed to vehicle data_1
-- 3) App2 is subscribed to vehicle data_1
-- 4) App1 requests UnregisterAppInterface
-- SDL does:
-- a) not send UnsubscriveVehicleData request to HMI during the unregistration of App1
-- 5)App2 requests UnregisterAppInterface
-- SDL does:
-- a) send UnsubscriveVehicleData request to HMI during the unregistration of App2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local appId1 = 1
local appId2 = 2
local rpc = "SubscribeVehicleData"
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
  { rpc, vehicleData, appId1, isExpectedSubscribeVDonHMI })
runner.Step("App2 subscribes to fuelRange", common.processRPCSubscriptionSuccess,
  { rpc, vehicleData, appId2, isNotExpectedSubscribeVDonHMI })
runner.Step("OnVehicleData to both apps", common.checkNotificationSuccess2Apps, { vehicleData })
runner.Step("Unregister App1", common.unregisterAppWithUnsubscription,
  { vehicleData, appId1, isNotExpectedSubscribeVDonHMI })
runner.Step("Unregister App2", common.unregisterAppWithUnsubscription,
  { vehicleData, appId2, isExpectedSubscribeVDonHMI })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
