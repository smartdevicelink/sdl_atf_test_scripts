---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check receiving StabilityControlsStatus data via GetVehicleData RPC
-- with other vehicle data parameters
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
--
-- Steps:
-- 1) App sends GetVehicleData (with stabilityControlsStatus = true, speed = true) request to SDL
--    SDL sends VehicleInfo.GetVehicleData (with stabilityControlsStatus = true, speed = true) request to HMI
--    HMI sends VehicleInfo.GetVehicleData response "SUCCESS"
--      with next data (stabilityControlsStatus: trailerSwayControl = "OFF", escSystem = "ON")
--      and (speed: value = 30.2)
--    SDL sends GetVehicleData response with data received from HMI
--      and (success: true, resultCode: "SUCCESS") to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData with StabilityControlsStatus and speed", common.processGetVDsuccessManyParameters,
  { "stabilityControlsStatus", "speed" })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
