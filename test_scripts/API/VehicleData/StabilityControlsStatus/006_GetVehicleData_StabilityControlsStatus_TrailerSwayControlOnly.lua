---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check receiving StabilityControlsStatus data
-- (with trailerSwayControl only) via GetVehicleData RPC
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
--
-- Steps:
-- 1) App sends GetVehicleData (with stabilityControlsStatus = true) request to SDL
--    SDL sends VehicleInfo.GetVehicleData (with stabilityControlsStatus = true) request to HMI
--    HMI sends VehicleInfo.GetVehicleData response "SUCCESS"
--      with next data only (trailerSwayControl = "OFF")
--    SDL sends GetVehicleData response with data received from HMI
--      and (success: true, resultCode: "SUCCESS") to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local stabilityControlsStatus = {
  value = {
    trailerSwayControl = "OFF"
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData with StabilityControlsStatus", common.processGetVDsuccess,
  { "stabilityControlsStatus", stabilityControlsStatus })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
