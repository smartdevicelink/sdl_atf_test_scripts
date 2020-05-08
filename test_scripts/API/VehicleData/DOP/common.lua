---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
-- local test = require("user_modules/dummy_connecttest")

--[[ Module ]]
local m = actions

m.gpsData = {
  longitudeDegrees = 10,
  latitudeDegrees = 20,
  utcYear = 2010,
  utcMonth = 1,
  utcDay = 2,
  utcHours = 3,
  utcMinutes = 4,
  utcSeconds = 5,
  compassDirection = "NORTH",
  actual = true,
  satellites = 6,
  dimension = "2D",
  altitude = 7,
  heading = 8,
  speed = 9,
  pdop = 10,
  hdop = 11,
  vdop = 12
}

m.params = { "pdop", "hdop", "vdop" }

function m.getGPSData()
  return utils.cloneTable(m.gpsData)
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

function m.checkAbsenceOfParam(pParam, pData)
  if pData.payload[pParam] ~= nil then
    return false, "Parameter '" .. pParam .. "' is not expected"
  end
  return true
end

function m.ptUpdate(pTbl)
  pTbl.policy_table.functional_groupings["Location-1"].user_consent_prompt = nil
end

return m
