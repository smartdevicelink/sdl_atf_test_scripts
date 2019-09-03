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
local runner = require('user_modules/script_runner')
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
local function processRPCSubscribeSuccess(self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc1.name, rpc1.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc1.name, rpc1.params)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", vehicleDataResults)
    end)

  local responseParams = common.cloneTable(vehicleDataResults)
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
end

local function checkNotification(pParams, isNotificationExpect, self)
  local mobileSession = common.getMobileSession(self, 1)
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { gps = pParams })
  if isNotificationExpect == true then
    mobileSession:ExpectNotification("OnVehicleData", { gps = pParams })
  else
    mobileSession:ExpectNotification("OnVehicleData")
    :Times(0)
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("SubscribeVehicleData gps", processRPCSubscribeSuccess)

runner.Title("Test")
for key, value in pairs(vehicleDataValues) do
  runner.Step("RPC OnVehicleData gps " .. key, checkNotification, { value, true })
end
for key, value in pairs(vehicleDataValuesMissedMandatory) do
  runner.Step("RPC OnVehicleData gps " .. key, checkNotification, { value, false })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
