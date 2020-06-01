---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2283
--
-- Description: SDL sends once VI.SubscribeVehicleData request to HMI during resumption of the same vehicle data
--  for 2 apps
--
-- In case:
-- 1) App1 and App2 are registered
-- 2) App1 and App2 are activated
-- 3) App1 and App2 send valid SubscribeVehicleData to SDL and these requests are allowed by Policies
-- 4) Apps reconnect is performed
-- SDL does:
-- a) start data resumption for both apps
-- b) transfer VI.SubscribeVehicleData request to HMI by the resumption of App1
-- c) resume the subscription for App1 after a receiving of the response from HMI
-- d) not transfer VI.SubscribeVehicleData request to HMI by the resumption of App2 and resume the subscription
--  for App2 internally
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
runner.Step("Disconnect mobile", common.disconnect)
runner.Step("Connect mobile", common.connect)
runner.Step("App1 registration with data resumption", common.raiWithDataResumption,
  { rpc, vehicleData, appId1, isExpectedSubscribeVDonHMI })
runner.Step("App2 registration with data resumption", common.raiWithDataResumption,
  { rpc, vehicleData, appId2, isNotExpectedSubscribeVDonHMI })
runner.Step("OnVehicleData to both apps", common.checkNotificationSuccess2Apps, { vehicleData })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
