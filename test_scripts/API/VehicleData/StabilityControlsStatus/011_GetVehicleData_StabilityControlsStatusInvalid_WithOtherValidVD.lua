---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check receiving stabilityControlsStatus (with invalid parameters)
-- and some other vehicle data (with valid parameters) via GetVehicleData RPC
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
--
-- Steps:
-- 1) App sends GetVehicleData (with stabilityControlsStatus = true) request to SDL
--    SDL sends VehicleInfo.GetVehicleData (with stabilityControlsStatus = true, speed = true) request to HMI
--    HMI sends VehicleInfo.GetVehicleData
--      response "SUCCESS", stabilityControlsStatus with invalid parameters
--    SDL sends to app GetVehicleData response with (success: false, resultCode: "GENERIC_ERROR")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Local Variables ]]
local reqParams = {
  stabilityControlsStatus = true,
  speed = true
}

-- trailerSwayControl is updated to boolean instead of VehicleDataStatus type
local hmiResParams_invalidTrailerSwayControl = {
  stabilityControlsStatus = {
    escSystem = "ON",
    trailerSwayControl = true
  },
  speed = 30.2
}

-- escSystem is updated to integer instead of VehicleDataStatus type
local hmiResParams_invalidEscSystem = {
  stabilityControlsStatus = {
    escSystem = 20,
    trailerSwayControl = "OFF"
  },
  speed = 30.2
}

-- escSystem is updated to float instead of VehicleDataStatus type
-- trailerSwayControl is updated to string instead of VehicleDataStatus type
local hmiResParams_invalidBothParams = {
  stabilityControlsStatus = {
    escSystem = 30.2,
    trailerSwayControl = "invalid"
  },
  speed = 30.2
}

-- stabilityControlsStatus in not a structure
local hmiResParams_stabilityControlsStatusIsNotStructure = {
  stabilityControlsStatus = "ON",
  speed = 30.2
}

-- stabilityControlsStatus parameter absent
local hmiResParams_stabilityControlsStatusAbsent = {
  speed = 30.2
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Send GetVehicleData, stabilityControlsStatus structure has invalid trailerSwayControl value",
  common.processGetVDGenericError, { reqParams, hmiResParams_invalidTrailerSwayControl })
common.Step("Send GetVehicleData, stabilityControlsStatus structure has invalid escSystem value",
  common.processGetVDGenericError, { reqParams, hmiResParams_invalidEscSystem })
common.Step("Send GetVehicleData, stabilityControlsStatus structure has invalid both value",
  common.processGetVDGenericError, { reqParams, hmiResParams_invalidBothParams })
common.Step("Send GetVehicleData, stabilityControlsStatus structure in not structure",
  common.processGetVDGenericError, { reqParams, hmiResParams_stabilityControlsStatusIsNotStructure })
common.Step("Send GetVehicleData, stabilityControlsStatus structure absent",
  common.processGetVDBaseSuccess, { reqParams, reqParams, hmiResParams_stabilityControlsStatusAbsent })

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
