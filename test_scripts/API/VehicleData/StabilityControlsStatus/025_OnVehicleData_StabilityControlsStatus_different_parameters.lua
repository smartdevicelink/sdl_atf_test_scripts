---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check receiving StabilityControlsStatus data via OnVehicleData notification
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
-- 5) App is subscribed on StabilityControlsStatus vehicle data
--
-- Steps:
-- 1) HMI sends VehicleInfo.OnVehicleData notification `stabilityControlsStatus` parameter
--     which contains  only `escSystem` parameter
--    SDL sends OnVehicleData notification with received from HMI data to App
-- 2) HMI sends VehicleInfo.OnVehicleData notification `stabilityControlsStatus` parameter
--     which contains  only `trailerSwayControl` parameter
--    SDL sends OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Functions ]]
local function checkNotificationSuccess(pData, pValue)
  local hmiNotParams = { [pData] = pValue }
  local mobNotParams = common.cloneTable(hmiNotParams)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
  common.getMobileSession():ExpectNotification("OnVehicleData", mobNotParams)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App1", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App1", common.activateApp)
common.Step("Subscribe on StabilityControlsStatus VehicleData", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", { "stabilityControlsStatus" }})

common.Title("Test")
common.Step("Expect OnVehicleData with StabilityControlsStatus with escSystem only",
  checkNotificationSuccess, { "stabilityControlsStatus", { escSystem = "ON" }})
common.Step("Expect OnVehicleData with StabilityControlsStatus with trailerSwayControl only",
  checkNotificationSuccess, { "stabilityControlsStatus", { trailerSwayControl = "OFF" }})

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
