---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes UnsubscribeVehicleData RPC for two Apps with 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPCs UnsubscribeVehicleData, SubscribeVehicleData and handsOffSteering parameter are allowed by policies
-- 3) App_1 and App_2 are registered and subscribed to handsOffSteering data
--
-- In case:
-- 1) App_1 sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
-- handsOffSteering = <data received from HMI>) to App_1
-- - c) not transfer this request to HMI
-- 2) App_2 sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 3) HMI sends VehicleInfo.UnsubscribeVehicleData response with handsOffSteering data to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
-- handsOffSteering = <data received from HMI>) to App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local appId_1 = 1
local appId_2 = 2
local isExpectedSubscribeVDonHMI = true
local isNotExpectedSubscribeVDonHMI = false
local notExpected = 0
local expected = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerApp, { appId_1 })
common.Step("Register App_2", common.registerAppWOPTU, { appId_2 })
common.Step("App_1 subscribes to handsOffSteering data",
  common.processSubscriptionRPC, { rpc_sub, appId_1, isExpectedSubscribeVDonHMI })
common.Step("App_2 subscribes to handsOffSteering data",
  common.processSubscriptionRPC, { rpc_sub, appId_2, isNotExpectedSubscribeVDonHMI })
common.Step("OnVehicleData notification for both apps",
  common.onVehicleDataTwoApps, { expected })

common.Title("Test")
common.Step("RPC " .. rpc_unsub .. " with handsOffSteering parameter for App_1",
  common.processSubscriptionRPC, { rpc_unsub, appId_1, isNotExpectedSubscribeVDonHMI })
common.Step("Absence of OnVehicleData notification for App_1", common.sendOnVehicleData, { notExpected })
common.Step("RPC " .. rpc_unsub .. " with handsOffSteering parameter for App_2",
  common.processSubscriptionRPC, { rpc_unsub, appId_2, isExpectedSubscribeVDonHMI })
common.Step("Absence of OnVehicleData notification for both apps",
  common.onVehicleDataTwoApps, { notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
