---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL resumes the subscription for `gearStatus` parameter for two Apps
-- after unexpected disconnect/connect.
--
-- Preconditions:
-- 1) App1 and App2 are registered and subscribed to `gearStatus` data
-- 2) Unexpected disconnect and reconnect are performed
-- In case:
-- 1) App1 re-registers with actual HashId
-- SDL does:
-- - a) send VehicleInfo.SubscribeVehicleData(gearStatus=true) request to HMI during resumption
-- - b) process successful response from HMI
-- - c) restore subscription for gearStatus data
-- - d) respond RAI(SUCCESS) to mobile app
-- 2) App2 re-registers with actual HashId
-- SDL does:
-- - a) not send VehicleInfo.SubscribeVehicleData request to HMI during resumption
-- - b) restore subscription for gearStatus data internally
-- - c) respond RAI(SUCCESS) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
local appId1 = 1
local appId2 = 2
local isExpectedSubscribeVDonHMI = true
local isNotExpectedSubscribeVDonHMI = false
local isSubscribed = true
local notSubscribed = false

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App1", common.registerAppWOPTU, { appId1 })
common.Step("Register App2", common.registerAppWOPTU, { appId2 })
common.Step("Activate App1", common.activateApp, { appId1 })
common.Step("Activate App2", common.activateApp, { appId2 })
common.Step("App1 subscribes to gearStatus data", common.processSubscriptionRPC,
  { rpc, appId1, isExpectedSubscribeVDonHMI })
common.Step("App2 subscribes to gearStatus data", common.processSubscriptionRPC,
  { rpc, appId2, isNotExpectedSubscribeVDonHMI })
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)

common.Title("Test")
common.Step("Re-register App1 with data resumption", common.registerAppWithResumption, { appId1, isSubscribed })
common.Step("OnVehicleData notification to App1", common.sendOnVehicleData)
common.Step("Re-register App2 with data resumption", common.registerAppWithResumption, { appId2, notSubscribed })
common.Step("OnVehicleData with gearStatus data to both apps", common.onVehicleDataTwoApps)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
