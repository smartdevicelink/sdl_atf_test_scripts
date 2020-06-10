---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: UnsubscribeVehicleData RPC with `stabilityControlsStatus` parameter only,
-- invalid response from HMI related to this parameter
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
-- 5) App is subscribed on StabilityControlsStatus vehicle data
--
-- Steps:
-- 1) App sends UnsubscribeVehicleData (with stabilityControlsStatus = true) request to SDL
--    SDL sends VehicleInfo.UnsubscribeVehicleData (with stabilityControlsStatus = true) request to HMI
--    HMI sends invalid VehicleInfo.UnsubscribeVehicleData response
--    - empty structure
--    - stabilityControlsStatus is empty structure
--    - invalid parameter dataTypes
--    - invalid value for dataType
--    - stabilityControlsStatus is not a structure
--    SDL sends UnsubscribeVehicleData response with (success: false, resultCode: "GENERIC_ERROR")
-- 2) HMI sends VehicleInfo.OnVehicleData notifications with StabilityControlsStatus data
--    SDL sends OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local hmiResParams = {
  emptyStructure = {},
  stabilityControlsStatusEmpty = {
    stabilityControlsStatus = {},
  },
  invalidParameter = {
    stabilityControlsStatus = {
      dataTypes = common.allVehicleData.stabilityControlsStatus.type,
      resultCode = "SUCCESS"
    }
  },
  invalidValue = {
    stabilityControlsStatus = {
      dataType = "DATA_TYPE",
      resultCode = "SUCCESS"
    }
  },
  stabilityControlsStatusIsNotStructure = {
    stabilityControlsStatus = "ON"
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)
common.Step("Subscribe on StabilityControlsStatus VehicleData", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", { "stabilityControlsStatus" }})

common.Title("Test")
for k, v in pairs(hmiResParams) do
  common.Step("Unsubscribe from StabilityControlsStatus," .. k .. " in HMI response",
    common.processRPCSubscriptionGenericError, { "UnsubscribeVehicleData", { "stabilityControlsStatus"}, v })
  common.Step("Process OnVehicleData with StabilityControlsStatus data", common.checkNotificationSuccess,
    {{ "stabilityControlsStatus" }})
end

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
