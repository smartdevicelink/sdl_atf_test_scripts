---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2283
--
-- Description: SDL sends VI.SubscribeVehicleData request to HMI during resumption of 2 apps
--
-- In case:
-- 1) App1 and App2 are registered
-- 2) App1 and App2 are activated
-- 3) App1 requests SubscribeVehicleData(data_1) to SDL and this requests is allowed by Policies
-- 4) App2 requests SubscribeVehicleData(data_2) to SDL and this requests is allowed by Policies
-- 5) Apps reconnect is performed
-- SDL does:
-- a) start data resumption for both apps
-- b) transfer VI.SubscribeVehicleData(data_1) request to HMI by resumption of App1
-- c) resume the subscription for App1 after a receiving of the response from HMI
-- d) transfer VI.SubscribeVehicleData(data_2) request to HMI by resumption of App2
-- e) resume the subscription for App2 after a receiving of the response from HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local appId1 = 1
local appId2 = 2
local rpc = "SubscribeVehicleData"
local vehicleDataForApp1 = "fuelRange"
local vehicleDataForApp2 = "tirePressure"

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
runner.Step("App1 subscribes to fuelRange", common.processRPCSubscriptionSuccess, { rpc, vehicleDataForApp1, appId1 })
runner.Step("App2 subscribes to tirePressure", common.processRPCSubscriptionSuccess, { rpc, vehicleDataForApp2, appId2 })
runner.Step("Disconnect mobile", common.disconnect)
runner.Step("Connect mobile", common.connect)
runner.Step("App1 registration with data resumption", common.raiWithDataResumption, { rpc, vehicleDataForApp1, appId1 })
runner.Step("App2 registration with data resumption", common.raiWithDataResumption, { rpc, vehicleDataForApp2, appId2 })
runner.Step("OnVehicleData to App1", common.checkNotificationSuccess, { vehicleDataForApp1, appId1 })
runner.Step("OnVehicleData to App2", common.checkNotificationSuccess, { vehicleDataForApp2, appId2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
