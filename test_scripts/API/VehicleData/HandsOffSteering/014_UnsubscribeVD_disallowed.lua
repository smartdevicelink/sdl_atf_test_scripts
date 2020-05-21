---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects UnsubscribeVehicleData request with resultCode "DISALLOWED" if
-- `handsOffSteering` parameter is not allowed by policy
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) `handsOffSteering` parameter is not allowed by policies for UnsubscribeVehicleData RPC
-- 3) App is registered and subscribed to handsOffSteering data
--
-- In case:
-- 1) App sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = "DISALLOWED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local result = "DISALLOWED"
local VDGroup = {
  rpcs = {
    SubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = {"handsOffSteering"}
    },
    UnsubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = { "gps" }
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions, { VDGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to handsOffSteering data", common.processSubscriptionRPC, { rpc_sub })

common.Title("Test")
common.Step("RPC " .. rpc_unsub .. " with handsOffSteering parameter DISALLOWED",
  common.processRPCFailure, { rpc_unsub, result })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
