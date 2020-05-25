---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL successfully processes SubscribeVehicleData with `gearStatus` parameter.
--
-- In case:
-- 1) App sends SubscribeVehicleData request with gearStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI responds with `SUCCESS` result to `gearStatus` vehicle data and SubscribeVehicleData request.
-- SDL does:
--  a) respond `SUCCESS`, success:true with `gearStatus` data to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { rpc })
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
