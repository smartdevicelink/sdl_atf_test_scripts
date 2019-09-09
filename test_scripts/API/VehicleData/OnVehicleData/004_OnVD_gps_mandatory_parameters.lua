---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case 1: TO ADD!!!
--
-- Requirement summary:
-- [OnVehicleData] As a mobile app is subscribed for VI parameter
-- and received notification about this parameter change from hmi
--
-- Description:
-- In case:
-- 1) If application is subscribed to get vehicle data with 'gps' parameter
-- 2) Notification about changes with mandatory parameters is received from hmi
-- 3) Notification about changes without mandatory parameters is received from hmi
-- SDL must:
-- 1) Forward this notification to mobile application
-- 2) Not forward this notification to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc1 = {
  name = "SubscribeVehicleData",
  params = {
    gps = true
  }
}

local vehicleDataResults = {
  gps = {
    dataType = "VEHICLEDATA_GPS",
    resultCode = "SUCCESS"
  }
}

local vehicleDataValues = {
  allData = {
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
  },
  mandatoryOnly = {
    longitudeDegrees = 10,
    latitudeDegrees = 20
  }
}

local vehicleDataValuesMissedMandatory = {
  missedAll = { utcYear = 2010 },
  missedLongitude = { latitudeDegrees = 20 },
  missedLatitude = { longitudeDegrees = 10 }
}

--[[ Local Functions ]]
local function processRPCSubscribeSuccess()
  local cid = common.getMobileSession():SendRPC(rpc1.name, rpc1.params)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc1.name, rpc1.params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", vehicleDataResults)
    end)

  local responseParams = vehicleDataResults
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, responseParams)
end

local function checkNotification(pParams, isNotificationExpect)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = pParams })
  if isNotificationExpect == true then
    common.getMobileSession():ExpectNotification("OnVehicleData", { gps = pParams })
  else
    common.getMobileSession():ExpectNotification("OnVehicleData")
    :Times(0)
  end
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)
common.Step("SubscribeVehicleData gps", processRPCSubscribeSuccess)

common.Title("Test")
for key, value in pairs(vehicleDataValues) do
  common.Step("RPC OnVehicleData gps " .. key, checkNotification, { value, true })
end
for key, value in pairs(vehicleDataValuesMissedMandatory) do
  common.Step("RPC OnVehicleData gps " .. key, checkNotification, { value, false })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
