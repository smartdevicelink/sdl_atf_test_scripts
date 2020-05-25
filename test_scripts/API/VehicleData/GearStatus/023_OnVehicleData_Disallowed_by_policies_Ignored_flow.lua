---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL does not forward a OnVehicleData notification with 'gearStatus' data to App in case
-- `gearStatus` parameter does not exist in app assigned policies.
--
-- Preconditions:
-- 1) `gearStatus` parameter does not exist in app assigned policies for OnVehicleData RPC.
-- 2) App is subscribed to `gearStatus` data.
-- In case:
-- 1) HMI sends valid OnVehicleData notification with `gearStatus` data.
-- SDL does:
--  a) ignore this notification.
--  b) not send OnVehicleData notification to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
local notExpected = 0
local preloadedFileUpdate = true
local vehicleDataGroup = {
  rpcs = {
    SubscribeVehicleData = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
      parameters = { "gearStatus" }
    },
    OnVehicleData = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
      parameters = { "gps" }
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions, { preloadedFileUpdate, vehicleDataGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { rpc })

common.Title("Test")
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData,
  { common.getGearStatusParams(), notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
