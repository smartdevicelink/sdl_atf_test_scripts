---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check receiving stabilityControlsStatus (with valid parameters)
-- and some other vehicle date (with invalid parameters) via GetVehicleData RPC
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
--
-- Steps:
-- 1) App sends GetVehicleData (with stabilityControlsStatus = true, speed = true) request to SDL
--    SDL sends VehicleInfo.GetVehicleData (with stabilityControlsStatus = true, speed = true) request to HMI
--    HMI sends VehicleInfo.GetVehicleData response
--      with "SUCCESS", speed has invalid parameters
--    SDL sends to app GetVehicleData response with (success: false, resultCode: "GENERIC_ERROR")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local reqParams = {
  stabilityControlsStatus = true,
  speed = true
}

-- speed is updated to string instead of float type
local hmiResParams_invalidSpeedAsString = {
  stabilityControlsStatus = {
    escSystem = "ON",
    trailerSwayControl = "OFF"
  },
  speed = "invalid"
}

-- speed is updated to boolean instead of float type
local hmiResParams_invalidSpeedAsBool = {
  stabilityControlsStatus = {
    escSystem = "ON",
    trailerSwayControl = "OFF"
  },
  speed = true
}

-- speed has type structure instead of float
local hmiResParams_invalidSpeedType = {
  stabilityControlsStatus = {
    escSystem = "ON",
    trailerSwayControl = "OFF"
  },
  speed = {
    value = 20.2
  }
}

-- speed value is above the limit
local hmiResParams_outrangeSpeed = {
  stabilityControlsStatus = {
    escSystem = "ON",
    trailerSwayControl = "OFF"
  },
  speed = 1000
}

-- speed parameter absent
local hmiResParams_speedAbsent = {
  stabilityControlsStatus = {
    escSystem = "ON",
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
common.Step("Send GetVehicleData, speed structure invalid",
  common.processGetVDGenericError, { reqParams, hmiResParams_invalidSpeedAsString })
common.Step("Send GetVehicleData, speed structure invalid",
  common.processGetVDGenericError, { reqParams, hmiResParams_invalidSpeedAsBool })
common.Step("Send GetVehicleData, other structure has invalid values",
  common.processGetVDGenericError, { reqParams, hmiResParams_invalidSpeedType })
common.Step("Send GetVehicleData, speed structure has outrange value",
  common.processGetVDGenericError, { reqParams, hmiResParams_outrangeSpeed })
common.Step("Send GetVehicleData, stabilityControlsStatus structure absent",
  common.processGetVDBaseSuccess, { reqParams, reqParams, hmiResParams_speedAbsent })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
