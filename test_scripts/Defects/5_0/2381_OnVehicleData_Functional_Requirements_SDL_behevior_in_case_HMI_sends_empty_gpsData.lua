---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2381
--
-- Precondition:
-- SDL Core and HMI are started. App is registered, HMI level = FULL
-- Description:
-- Steps to reproduce:
-- 1) In case HMI sends OnVehilceData_notification with; -> 'gpsData' and this structure is empty (has no parameters)
-- Expected:
-- 1) Treat OnVehicleData_response as invalid
-- 2) Log corresponding error internally
-- 3) Ignore received notification (thus, should NOT send this notification to mobile app)
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local variable ]]
local gpsData = {
  longitudeDegrees = 42.5,
  latitudeDegrees = -83.3,
  utcYear = 2013,
  utcMonth = 2,
  utcDay = 14,
  utcHours = 13,
  utcMinutes = 16,
  utcSeconds = 54,
  compassDirection = "SOUTHWEST",
  pdop = 9,
  hdop = 6.9,
  vdop = 6.2,
  actual = false,
  satellites =  8,
  dimension = "2D",
  altitude = 7.7,
  heading = 173.99,
  speed = 2.78
}

--[[ Local Functions ]]
local function subscribeVehicleData()
  local gpsResponseData = {
    dataType = "VEHICLEDATA_GPS",
    resultCode = "SUCCESS"
  }
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", { gps = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { gps = true })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = gpsResponseData })
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gps = gpsResponseData })
end

local function sendOnVehicleDataFull(param)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = param})
  common.getMobileSession():ExpectNotification("OnVehicleData", { gps = param })
end

local function sendOnVehicleDataEmpty()
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = {} })
  common.getMobileSession():ExpectNotification("OnVehicleData")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Subscribe GPS VehicleData", subscribeVehicleData)
runner.Step("Send OnVehicleData with full structure", sendOnVehicleDataFull, { gpsData })
runner.Step("Send OnVehicleData with empty structure", sendOnVehicleDataEmpty)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
