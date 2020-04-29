---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL processes UnsubscribeVehicleData RPC for two Apps with `windowStatus` parameter
--
-- Preconditions:
-- 1) SubscribeVehicleData, UnsubscribeVehicleData RPCs and `windowStatus` parameter are allowed by policies
-- 2) App_1 and App_2 are registered
-- 3) App_1 and App_2  are subscribed to windowStatus data
--
-- In case:
-- 1) App_1 requests UnsubscribeVehicleData(windowStatus=true)
-- SDL does:
--  a) not transfer this request to HMI
--  b) send UnsubscribeVehicleData(success = true, resultCode = SUCCESS", windowStatus = <data received from HMI>)
--  response to App_2
-- 2) App_2 requests UnsubscribeVehicleData(windowStatus=true)
-- SDL does:
--  a) transfer this request to HMI
-- 3) HMI sends successful VehicleInfo.UnsubscribeVehicleData response with windowStatus data to SDL
-- SDL does:
--  a) send UnsubscribeVehicleData(success = true, resultCode = SUCCESS", windowStatus = <data received from HMI>)
--  response to App_1
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variable ]]
local rpc = "UnsubscribeVehicleData"
local rpcSubscribe = "SubscribeVehicleData"
local firstAppId = 1
local secondAppId = 2
local isExpectedSubscribeVDonHMI = true
local notExpectedSubscribeVDonHMI = false
local isExpected = 1
local notExpected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerApp, { firstAppId })
common.Step("Register App_2", common.registerAppWOPTU, { secondAppId })
common.Step("App_1 subscribes to windowStatus data",
  common.subUnScribeVD, { rpcSubscribe, isExpectedSubscribeVDonHMI, firstAppId })
common.Step("App_2 subscribes to windowStatus data",
  common.subUnScribeVD, { rpcSubscribe, notExpectedSubscribeVDonHMI, secondAppId })
common.Step("OnVehicleData to App_1 and App_2", common.onVehicleDataTwoApps, { isExpected })

common.Title("Test")
common.Step("App_1 unsubscribes from windowStatus data",
  common.subUnScribeVD, { rpc, notExpectedSubscribeVDonHMI, firstAppId })
common.Step("Absence OnVehicleData for App_1", common.sendOnVehicleData,
  { common.getWindowStatusParams(), notExpected })
common.Step("App_2 unsubscribes from windowStatus data",
  common.subUnScribeVD, { rpc, isExpectedSubscribeVDonHMI, secondAppId })
common.Step("Absence OnVehicleData for both apps", common.onVehicleDataTwoApps, { notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
