---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL successful processes UnsubscribeVehicleData RPC with `gearStatus` param.
--
-- In case:
-- 1) App is subscribed to `gearStatus` data.
-- 2) App sends UnsubscribeVehicleData request with gearStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this requests to HMI.
-- 3) HMI responds with `SUCCESS` result to `gearStatus` vehicle data and UnsubscribeVehicleData request.
-- SDL does:
--  a) respond with resultCode:`SUCCESS` with `gearStatus` data to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local notExpected = 0
local expected = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { rpc_sub })
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData, { common.getGearStatusParams(), expected })

common.Title("Test")
common.Step("App unsubscribes from gearStatus data", common.processSubscriptionRPC, { rpc_unsub })
common.Step("Absence OnVehicleData with gearStatus data", common.sendOnVehicleData,
  { common.getGearStatusParams(), notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
