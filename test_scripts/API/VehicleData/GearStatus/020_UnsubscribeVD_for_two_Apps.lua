---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: Check that SDL processes UnsubscribeVehicleData RPC for two Apps with `gearStatus` parameter
--
-- Preconditions:
-- 1) SubscribeVehicleData, UnsubscribeVehicleData RPCs and `gearStatus` parameter are allowed by policies
-- 2) App_1 and App_2 are registered
-- 3) App_1 and App_2  are subscribed to gearStatus data
-- In case:
-- 1) App_1 requests UnsubscribeVehicleData(gearStatus=true)
-- SDL does:
--  a) not transfer this request to HMI
--  b) send UnsubscribeVehicleData(success = true, resultCode = SUCCESS", gearStatus = <data received from HMI>)
--  response to App_2
-- 2) App_2 requests UnsubscribeVehicleData(gearStatus=true)
-- SDL does:
--  a) transfer this request to HMI
-- 3) HMI sends successful VehicleInfo.UnsubscribeVehicleData response with gearStatus data to SDL
-- SDL does:
--  a) send UnsubscribeVehicleData(success = true, resultCode = SUCCESS", gearStatus = <data received from HMI>)
--  response to App_1
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variable ]]
local rpc_unsub = "UnsubscribeVehicleData"
local rpc_sub = "SubscribeVehicleData"
local appId1 = 1
local appId2 = 2
local isExpectedSubscribeVDonHMI = true
local isNotExpectedSubscribeVDonHMI = false
local expected = 1
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerApp, { appId1 })
common.Step("Register App_2", common.registerAppWOPTU, { appId2 })
common.Step("App_1 subscribes to gearStatus data",
  common.processSubscriptionRPC, { rpc_sub, appId1, isExpectedSubscribeVDonHMI })
common.Step("App_2 subscribes to gearStatus data",
  common.processSubscriptionRPC, { rpc_sub, appId2, isNotExpectedSubscribeVDonHMI })
common.Step("OnVehicleData notification for both apps", common.onVehicleDataTwoApps, { expected })

common.Title("Test")
common.Step("App_1 unsubscribes from gearStatus data",
  common.processSubscriptionRPC, { rpc_unsub, appId1, isNotExpectedSubscribeVDonHMI })
common.Step("Absence OnVehicleData for App_1", common.sendOnVehicleData,
  { common.getGearStatusParams(), notExpected })
common.Step("App_2 unsubscribes from gearStatus data",
  common.processSubscriptionRPC, { rpc_unsub, appId2, isExpectedSubscribeVDonHMI })
common.Step("Absence OnVehicleData for both apps", common.onVehicleDataTwoApps, { notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
