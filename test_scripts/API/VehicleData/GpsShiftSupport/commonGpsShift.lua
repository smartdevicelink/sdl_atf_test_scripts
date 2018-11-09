---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
 --[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')

--[[ Variables ]]
local m = actions
m.cloneTable = utils.cloneTable

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
    speed =  2.78
}

m.radioData = { moduleType = "RADIO" }
m.radioData.radioControlData = {
    frequencyInteger = 1,
    frequencyFraction = 2,
    band = "AM",
    rdsData = {
        PS = "ps",
        RT = "rt",
        CT = "123456789012345678901234",
        PI = "pi",
        PTY = 1,
        TP = false,
        TA = true,
        REG = "US"
    },
    availableHDs = 1,
    hdChannel = 1,
    signalStrength = 5,
    signalChangeThreshold = 10,
    radioEnable = true,
    state = "ACQUIRING",
    hdRadioEnable = true,
    sisData = {
        stationShortName = "Name1",
        stationIDNumber = {
            countryCode = 100,
            fccFacilityId = 100
        },
        stationLongName = "RadioStationLongName",
        stationLocation = {
            longitudeDegrees = 0.1,
            latitudeDegrees = 0.1,
            altitude = 0.1
        },
        stationMessage = "station message"
    }
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

function m.getInteriorVehicleData(pShiftValue, pIsSubscribed)
    if not pIsSubscribed then pIsSubscribed = false end
    m.radioData.radioControlData.sisData.stationLocation.shifted = pShiftValue
    local cid = m.getMobileSession():SendRPC("GetInteriorVehicleData", {
        moduleType = "RADIO",
        subscribe = true
    })
    EXPECT_HMICALL("RC.GetInteriorVehicleData", {
        moduleType = "RADIO",
        subscribe = true
      })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
            moduleData = m.radioData,
            isSubscribed = pIsSubscribed
          })
    end)
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
      isSubscribed = pIsSubscribed,
      moduleData = m.radioData
    })
end

function m.onInteriorVehicleData(pShiftValue)
    m.radioData.radioControlData.sisData.stationLocation.shifted = pShiftValue
    m.getHMIConnection():SendNotification("RC.OnInteriorVehicleData", { moduleData = m.radioData })
    m.getMobileSession():ExpectNotification("OnInteriorVehicleData", { moduleData = m.radioData })
end

return m
