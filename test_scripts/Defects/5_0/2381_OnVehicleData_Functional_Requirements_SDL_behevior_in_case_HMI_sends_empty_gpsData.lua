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
-- 3) Ignore received notification (thus, should NOT send this notification to mobile app(s))
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

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

function sendOnVehicleData()
    local gpsData = {}
    common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = gpsData })
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
runner.Step("Send OnVehicleData with empty structure", sendOnVehicleData)


-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
