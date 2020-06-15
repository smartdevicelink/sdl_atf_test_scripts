---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check receiving StabilityControlsStatus and other parameters data
-- via OnVehicleData notification
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
-- 5) App is subscribed on StabilityControlsStatus and some other vehicle data parameters
--
-- Steps:
-- 1) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus and some
--     other vehicle data parameters
--    SDL sends OnVehicleData notification with received from HMI data to App
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
common.Step("Register App1", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App1", common.activateApp)
common.Step("Subscribe on StabilityControlsStatus and other parameters", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", vehicle_data_items })

common.Title("Test")
common.Step("Expect OnVehicleData with StabilityControlsStatus and other parameters",
  common.checkNotificationSuccess, { vehicle_data_items })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
