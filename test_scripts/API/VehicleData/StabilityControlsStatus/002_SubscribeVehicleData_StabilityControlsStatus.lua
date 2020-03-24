---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check subscription on StabilityControlsStatus data via SubscribeVehicleData RPC
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated

-- Steps:
-- 1) App send SubscribeVehicleData (with stabilityControlsStatus = true) request to SDL
-- SDL does:
--  - send VehicleInfo.SubscribeVehicleData (with stabilityControlsStatus = true) request to HMI
-- HMI sends VehicleInfo.SubscribeVehicleData response "SUCCESS"
--   with next data (stabilityControlsStatus = { dataType = "VEHICLEDATA_STABILITYCONTROLSSTATUS"} )
-- SDL does:
--  - send SubscribeVehicleData response with (success: true resultCode: "SUCCESS") and received from HMI data to App
-- 2) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus data
--   (escSystem = "ON", trailerSwayControl = "OFF")
-- SDL does:
--  - send OnVehicleData notification with received from HMI data to App
-- 3) HMI sends VehicleInfo.OnVehicleData notification with GPS data
-- SDL does:
--  - not send OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
-- local common = require('test_scripts/API/VehicleData/StabilityControlsStatus/commonVDStabilityControlsStatus')
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
-- common.Step("Prepare preloaded policy table", common.preparePreloadedPT)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Subscribe on StabilityControlsStatus VehicleData", common.processRPCSubscriptionSuccess,
  {"SubscribeVehicleData", "stabilityControlsStatus" })
common.Step("Expect OnVehicleData with StabilityControlsStatus data", common.checkNotificationSuccess,
  { "stabilityControlsStatus" })
common.Step("Ignore OnVehicleData with GPS data", common.checkNotificationIgnored, { "gps" })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
