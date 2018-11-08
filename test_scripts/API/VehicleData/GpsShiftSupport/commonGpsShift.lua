---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
 --[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Variables ]]
local m = actions

m.shiftValue = {
    true,
    false
}

m.gpsParams = {
    longitudeDegrees = 42.5,
    latitudeDegrees = -83.3,
    utcYear = 2013,
    utcMonth = 2,
    utcDay = 14,
    utcHours = 13,
    utcMinutes = 16,
    utcSeconds = 54,
    compassDirection = "SOUTHWEST",
    pdop = 8.4,
    hdop = 5.9,
    vdop = 3.2,
    actual = false,
    satellites = 8,
    dimension = "2D",
    altitude = 7.7,
    heading = 173.99,
    speed =  2.78,
    shifted
}

--[[ Functions ]]
function m.getVehicleData(pShiftValue)
    m.gpsParams.shifted = pShiftValue
    local cid = m.getMobileSession():SendRPC("GetVehicleData", { gps = true })
    EXPECT_HMICALL("VehicleInfo.GetVehicleData", { gps = true })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = m.gpsParams })
    end)
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gps = m.gpsParams })
end

function m.subscribeVehicleData()
    local gpsResponseData = {
        dataType = "VEHICLEDATA_GPS",
        resultCode = "SUCCESS"
      }
    local cid = m.getMobileSession():SendRPC("SubscribeVehicleData", { gps = true })
    EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData", { gps = true })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = gpsResponseData })
    end)
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gps = gpsResponseData })
end

function m.sendOnVehicleData(pShiftValue)
    m.gpsParams.shifted = pShiftValue
    m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = m.gpsParams })
    m.getMobileSession():ExpectNotification("OnVehicleData", { gps = m.gpsParams })
end

return m
