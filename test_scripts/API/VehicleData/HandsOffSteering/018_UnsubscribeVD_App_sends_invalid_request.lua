---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL responds with resultCode "INVALID_DATA" to UnsubscribeVehicleData request if App sends
-- request with invalid data
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPCs UnsubscribeVehicleData, SubscribeVehicleData and handsOffSteering parameter are allowed by policies
-- 3) App is registered and subscribed to handsOffSteering parameter
--
-- In case:
-- 1) App sends invalid UnsubscribeVehicleData(handsOffSteering=123) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = "INVALID_DATA") to App
-- - c) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local result = "INVALID_DATA"
local invalidData = 123

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to handsOffSteering data", common.processSubscriptionRPC, { rpc_sub })

common.Title("Test")
common.Step("RPC UnsubscribeVehicleData, App sends invalid request",
  common.processRPCFailure, { rpc_unsub, result, invalidData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
