---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
 --[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local commonRC = require("test_scripts/RC/commonRC")

--[[ Variables ]]
local m = actions
m.cloneTable = utils.cloneTable
m.preconditionsRC = commonRC.preconditions
m.postconditionsRC = commonRC.postconditions
m.radioData = commonRC.getModuleControlData("RADIO")
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

--[[ Functions ]]
function m.pTUpdateFunc(tbl)
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = {"Base-4", "Location-1"}
    tbl.policy_table.functional_groupings["Location-1"].user_consent_prompt = nil
end

function m.checkShifted(data, pShiftValue)
    if pShiftValue == nil and data ~= nil then
        return false, "Vehicle data contains unexpected shifted parameter"
    end
    return true
end

function m.getVehicleData(pShiftValue)
    m.gpsParams.shifted = pShiftValue
    local cid = m.getMobileSession():SendRPC("GetVehicleData", { gps = true })
    m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { gps = true })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = m.gpsParams })
    end)
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gps = m.gpsParams })
    :ValidIf(function(_, data)
        return m.checkShifted(data.payload.gps.shifted, pShiftValue)
    end)
end

function m.subscribeVehicleData()
    local gpsResponseData = {
        dataType = "VEHICLEDATA_GPS",
        resultCode = "SUCCESS"
      }
    local cid = m.getMobileSession():SendRPC("SubscribeVehicleData", { gps = true })
    m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { gps = true })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = gpsResponseData })
    end)
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gps = gpsResponseData })
end

function m.sendOnVehicleData(pShiftValue)
    m.gpsParams.shifted = pShiftValue
    m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = m.gpsParams })
    m.getMobileSession():ExpectNotification("OnVehicleData", { gps = m.gpsParams })
    :ValidIf(function(_, data)
        return m.checkShifted(data.payload.gps.shifted, pShiftValue)
    end)
end

function m.getInteriorVehicleData(pShiftValue, pIsSubscribed)
    if not pIsSubscribed then pIsSubscribed = false end
    m.radioData.radioControlData.sisData.stationLocation.shifted = pShiftValue
    local cid = m.getMobileSession():SendRPC("GetInteriorVehicleData", {
        moduleType = "RADIO",
        subscribe = true
    })
    m.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", {
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
    :ValidIf(function(_, data)
        return m.checkShifted(data.payload.moduleData.radioControlData.sisData.stationLocation.shifted, pShiftValue)
    end)
end

function m.onInteriorVehicleData(pShiftValue)
    m.radioData.radioControlData.sisData.stationLocation.shifted = pShiftValue
    m.getHMIConnection():SendNotification("RC.OnInteriorVehicleData", { moduleData = m.radioData })
    m.getMobileSession():ExpectNotification("OnInteriorVehicleData", { moduleData = m.radioData })
    :ValidIf(function(_, data)
        return m.checkShifted(data.payload.moduleData.radioControlData.sisData.stationLocation.shifted, pShiftValue)
    end)
end

return m
