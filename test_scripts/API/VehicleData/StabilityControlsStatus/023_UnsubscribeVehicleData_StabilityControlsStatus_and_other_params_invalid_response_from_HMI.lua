---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: UnsubscribeVehicleData RPC with `stabilityControlsStatus` and other parameters,
-- invalid response from HMI related to `stabilityControlsStatus` parameter
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
--    HMI sends invalid VehicleInfo.UnsubscribeVehicleData response related to `stabilityControlsStatus` parameter
--     - empty structure
--      - stabilityControlsStatus is empty structure
--      - invalid parameter dataTypes in stabilityControlsStatus
--      - invalid dataType value in stabilityControlsStatus
--      - stabilityControlsStatus is not a structure
--    SDL sends UnsubscribeVehicleData response with (success: false, resultCode: "GENERIC_ERROR")
-- 2) HMI sends VehicleInfo.OnVehicleData notifications with StabilityControlsStatus data
--    SDL sends OnVehicleData notification with received from HMI data to App
-- 3) HMI sends VehicleInfo.OnVehicleData notifications with GPS data
--    SDL sends OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Local Variables ]]
local hmiResParams = {
  emptyStructure = {},
  stabilityControlsStatusEmpty = {
    stabilityControlsStatus = {},
    gps = {
      dataTypes = common.allVehicleData.gps.type,
      resultCode = "SUCCESS"
    }
  },
  invalidParameter = {
    stabilityControlsStatus = {
      dataTypes = "VEHICLEDATA_STABILITYCONTROLSSTATUS",
      resultCode = "SUCCESS"
    },
    gps = {
      dataTypes = common.allVehicleData.gps.type,
      resultCode = "SUCCESS"
    }
  },
  invalidValue = {
    stabilityControlsStatus = {
      dataType = "DATA_TYPE",
      resultCode = "SUCCESS"
    },
    gps = {
      dataTypes = common.allVehicleData.gps.type,
      resultCode = "SUCCESS"
    }
  },
  stabilityControlsStatusIsNotStructure = {
    stabilityControlsStatus = "ON",
    gps = {
      dataTypes = common.allVehicleData.gps.type,
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
common.Step("Subscribe on StabilityControlsStatus VehicleData", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", { "stabilityControlsStatus", "gps" } })

common.Title("Test")
for k, v in pairs(hmiResParams) do
  common.Step("Unsubscribe from StabilityControlsStatus," .. k .. " in HMI response",
    common.processRPCSubscriptionGenericError, { "UnsubscribeVehicleData", { "stabilityControlsStatus", "gps" }, v })
  common.Step("Process OnVehicleData with StabilityControlsStatus data", common.checkNotificationSuccess,
    {{ "stabilityControlsStatus" }})
  common.Step("Process OnVehicleData with GPS data", common.checkNotificationSuccess, {{ "gps" }})
end

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
