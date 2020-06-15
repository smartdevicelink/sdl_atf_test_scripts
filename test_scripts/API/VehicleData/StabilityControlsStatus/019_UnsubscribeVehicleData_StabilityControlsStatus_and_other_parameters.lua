---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: UnsubscribeVehicleData RPC with `stabilityControlsStatus` and other parameters
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
-- 5) App is subscribed on StabilityControlsStatus and some other vehicle data
--
-- Steps:
-- 1) App sends UnsubscribeVehicleData requests to SDL (for all subscribed vehicle data items)
--    SDL sends VehicleInfo.UnsubscribeVehicleData (with stabilityControlsStatus = true and
--      all other subscribed vehicle data items) request to HMI
--    HMI sends VehicleInfo.UnsubscribeVehicleData response "SUCCESS" with (stabilityControlsStatus =
--      {dataType = "VEHICLEDATA_STABILITYCONTROLSSTATUS"}) and with data related to all subscribed vehicle data items
--    SDL sends UnsubscribeVehicleData response with (success: true, resultCode: "SUCCESS")
--      and received from HMI data to the App
-- 2) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus data
--      (escSystem = "ON", trailerSwayControl = "OFF") and with all other subscribed vehicle data items
--    SDL does not send OnVehicleData notification with received from HMI data to App
-- 3) HMI sends VehicleInfo.OnVehicleData notification with parameter which app has not been subscribed on previously
--    SDL does not send OnVehicleData notification with received data related to parameter which app
--      has not been subscribed on previously
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Local Variables ]]
local vehicle_data_items = {"gps", "speed", "rpm", "stabilityControlsStatus"}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)
common.Step("Subscribe on gps, speed, rpm, stabilityControlsStatus",
  common.processRPCSubscriptionSuccess, { "SubscribeVehicleData", vehicle_data_items })

common.Title("Test")
common.Step("Unsubscribe from gps, speed, rpm, stabilityControlsStatus",
  common.processRPCSubscriptionSuccess, { "UnsubscribeVehicleData", vehicle_data_items })

for _, item in pairs(vehicle_data_items) do
  common.Step("Ignore OnVehicleData with " .. item .. " data", common.checkNotificationIgnored, {{ item }})
end
common.Step("Ignore OnVehicleData with fuelLevel data", common.checkNotificationIgnored, {{ "fuelLevel" }})

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
