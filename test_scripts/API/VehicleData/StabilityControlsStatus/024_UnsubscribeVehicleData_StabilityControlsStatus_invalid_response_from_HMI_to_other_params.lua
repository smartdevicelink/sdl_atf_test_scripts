---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: UnsubscribeVehicleData RPC with `stabilityControlsStatus` and other parameters,
-- invalid response from HMI related to other parameter
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
-- 5) App is subscribed on StabilityControlsStatus and GPS vehicle data
--
-- Steps:
-- 1) App sends UnsubscribeVehicleData (with stabilityControlsStatus = true and gps = true) request to SDL
--    SDL sends VehicleInfo.UnsubscribeVehicleData (with stabilityControlsStatus = true and gps = true) request to HMI
--    HMI sends invalid VehicleInfo.UnsubscribeVehicleData response related to `gps` parameter
--      - empty structure
--      - gps is empty structure
--      - invalid parameter dataTypes in gps
--      - invalid dataType value in gps
--      - gps is not a structure
--    SDL sends UnsubscribeVehicleData response with (success: false, resultCode: "GENERIC_ERROR")
-- 2) HMI sends VehicleInfo.OnVehicleData notifications with StabilityControlsStatus data
--    SDL sends OnVehicleData notification with received from HMI data to App
--    HMI sends VehicleInfo.OnVehicleData notifications with GPS data
--    SDL sends OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local hmiResParams = {
  emptyStructure = {},
  gpsEmpty = {
    gps = {},
    stabilityControlsStatus = {
      dataTypes = common.allVehicleData.stabilityControlsStatus.type,
      resultCode = "SUCCESS"
    }
  },
  gpsInvalidParameter = {
    gps = {
      dataTypes = common.allVehicleData.gps.type,
      resultCode = "SUCCESS"
    },
    stabilityControlsStatus = {
      dataType = common.allVehicleData.stabilityControlsStatus.type,
      resultCode = "SUCCESS"
    }
  },
  gpsInvalidValue = {
    gps = {
      dataType = "DATA_TYPE",
      resultCode = "SUCCESS"
    },
    stabilityControlsStatus = {
      dataTypes = common.allVehicleData.stabilityControlsStatus.type,
      resultCode = "SUCCESS"
    }
  },
  gpsIsNotStructure = {
    gps = "ON",
    stabilityControlsStatus = {
      dataTypes = common.allVehicleData.stabilityControlsStatus.type,
      resultCode = "SUCCESS"
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)
common.Step("Subscribe on StabilityControlsStatus and GPS VehicleData", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", { "stabilityControlsStatus", "gps" } })

common.Title("Test")
for k, v in pairs(hmiResParams) do
  common.Step("Unsubscribe from StabilityControlsStatus," .. k .. " in HMI response",
    common.processRPCSubscriptionGenericError, { "UnsubscribeVehicleData", { "stabilityControlsStatus", "gps" } , v })
  common.Step("Process OnVehicleData with StabilityControlsStatus data", common.checkNotificationSuccess,
    {{ "stabilityControlsStatus" }})
  common.Step("Process OnVehicleData with GPS data", common.checkNotificationSuccess, {{ "gps" }})
end

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
