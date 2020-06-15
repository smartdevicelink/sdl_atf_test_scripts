---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: Check that SDL rejects UnsubscribeVehicleData request with resultCode "IGNORED" in case
--  app is already unsubscribed from 'gearStatus' data
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) App is subscribed to 'gearStatus' data
-- 4) App is unsubscribed from 'gearStatus' data
--
-- In case:
-- 1) App sends valid UnsubscribeVehicleData(gearStatus=true) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = "IGNORED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
local unsub_rpc = "UnsubscribeVehicleData"
local result = "IGNORED"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to gearStatus parameter", common.processSubscriptionRPC, { rpc })
common.Step("App unsubscribes from gearStatus parameter", common.processSubscriptionRPC, { unsub_rpc })

common.Title("Test")
common.Step("RPC " .. unsub_rpc .. " with gearStatus parameter IGNORED",
  common.processRPCFailure, { unsub_rpc, result })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
