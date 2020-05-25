---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL rejects the request with `DISALLOWED` resultCode if app tries to unsubscribe from `gearStatus`
-- vehicle data in case `gearStatus` parameter does not exist in app assigned policies.
--
-- In case:
-- 1) `gearStatus` parameter does not exist in app assigned policies.
-- 2) App sends valid UnsubscribeVehicleData requests with gearStatus=true to the SDL.
-- SDL does:
--  a) not transfer this request to HMI.
--  b) send response UnsubscribeVehicleData(success:false, resultCode:`DISALLOWED`) to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "UnsubscribeVehicleData"
local result = "DISALLOWED"
local preloadedFileUpdate = true
local vehicleDataGroup = {
    rpcs = {
      UnsubscribeVehicleData = {
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

common.Title("Test")
common.Step("UnsubscribeVehicleData with gearStatus DISALLOWED", common.processRPCFailure, { rpc, result })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
