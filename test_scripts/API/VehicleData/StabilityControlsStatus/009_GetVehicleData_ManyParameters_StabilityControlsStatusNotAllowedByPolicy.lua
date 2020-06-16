---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description:
-- Check GetVehicleData RPC with `stabilityControlsStatus` parameter which is NOT allowed by
-- policies and other parameters which are allowed by Policies
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed, stabilityControlsStatus param is NOT allowed by Policies
-- 4) App is activated
--
-- Steps:
-- 1) App sends GetVehicleData (with stabilityControlsStatus = true, gps = true) request to SDL
--    SDL cuts off stabilityControlsStatus parameters as disallowed and sends
--      VehicleInfo.GetVehicleData ("gps:true" ) to HMI
-- 2) HMI sends VehicleInfo.GetVehicleData with response "SUCCESS"
--    SDL sends GetVehicleData_response to app with the same values as those received from HMI
--    ( success = true, resultCode = "SUCCESS", info = "'stabilityControlsStatus' is disallowed by policies." )
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU for gps", common.policyTableUpdate, { common.ptUpdateMin })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Send GetVehicleData, stabilityControlsStatus param is NOT allowed by Policies",
  common.processGetVDsuccessCutDisallowedParameters, { "stabilityControlsStatus", "gps" })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
