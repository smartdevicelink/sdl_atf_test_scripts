---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check subscription on StabilityControlsStatus and other parameters data
--   via SubscribeVehicleData RPC
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed, all vehicle data is allowed
-- 4) App is activated

-- Steps:
-- 1) App sends SubscribeVehicleData request with (stabilityControlsStatus = true, gps = true) to SDL
-- SDL sends VehicleInfo.SubscribeVehicleData request with (stabilityControlsStatus = true, gps = true) to HMI
-- HMI sends VehicleInfo.SubscribeVehicleData response "SUCCESS" with
--   (stabilityControlsStatus = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_STABILITYCONTROLSSTATUS"},
--   gps = { resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"})
-- SDL sends SubscribeVehicleData response with (success: true, resultCode: "SUCCESS") and
--   received from HMI data to App
-- 2) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus data
-- SDL sends OnVehicleData notification with received from HMI data to App
-- 3) HMI sends VehicleInfo.OnVehicleData notification with GPS data
-- SDL sends OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local variables ]]
local vdName1 = "gps"
local vdName2 = "stabilityControlsStatus"
local mobileRequest = {
  [vdName1] = true,
  [vdName2] = true
}
local hmiRequest = mobileRequest
local hmiResponse = {
  [vdName1] = common.getSubscribeVehicleDataHmiResponse("SUCCESS", vdName1),
  [vdName2] = common.getSubscribeVehicleDataHmiResponse("SUCCESS", vdName2)
}
local mobileResponse = {
  success = true,
  resultCode = "SUCCESS",
  [vdName1] = common.getSubscribeVehicleDataHmiResponse("SUCCESS", vdName1),
  [vdName2] = common.getSubscribeVehicleDataHmiResponse("SUCCESS", vdName2)
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Subscribe on " .. vdName1 .. " and " .. vdName2 .. " VehicleData",
  common.processSubscribeVD, { mobileRequest, hmiRequest, hmiResponse, mobileResponse })
common.Step("Expect OnVehicleData with " .. vdName2 .. " data",
  common.checkNotificationSuccess, {{ vdName2 }})
common.Step("Expect OnVehicleData with " .. vdName1 .. " data",
  common.checkNotificationSuccess, {{ vdName1 }})

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
