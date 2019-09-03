---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: UnsubscribeVehicleData
-- Item: Happy path
--
-- Requirement summary:
-- [UnsubscribeVehicleData] SUCCESS: getting SUCCESS:VehicleInfo.UnsubscribeVehicleData()
--
-- Description:
-- Mobile application sends valid UnsubscribeVehicleData request and gets VehicleInfo.UnsubscribeVehicleData "SUCCESS"
-- response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests UnsubscribeVehicleData with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if VehicleInfo interface is available on HMI
-- SDL checks if UnsubscribeVehicleData is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the VehicleInfo part of request with allowed parameters to HMI
-- SDL receives VehicleInfo part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Variables ]]
local VDValues = {
  gps = "VEHICLEDATA_GPS",
  speed = "VEHICLEDATA_SPEED",
  rpm = "VEHICLEDATA_RPM",
  fuelLevel = "VEHICLEDATA_FUELLEVEL",
  fuelLevel_State = "VEHICLEDATA_FUELLEVEL_STATE",
  fuelRange = "VEHICLEDATA_FUELRANGE",
  instantFuelConsumption = "VEHICLEDATA_FUELCONSUMPTION",
  externalTemperature = "VEHICLEDATA_EXTERNTEMP",
  prndl = "VEHICLEDATA_PRNDL",
  turnSignal = "VEHICLEDATA_TURNSIGNAL",
  tirePressure = "VEHICLEDATA_TIREPRESSURE",
  odometer = "VEHICLEDATA_ODOMETER",
  beltStatus = "VEHICLEDATA_BELTSTATUS",
  electronicParkBrakeStatus = "VEHICLEDATA_ELECTRONICPARKBRAKESTATUS",
  bodyInformation = "VEHICLEDATA_BODYINFO",
  deviceStatus = "VEHICLEDATA_DEVICESTATUS",
  driverBraking = "VEHICLEDATA_BRAKING",
  wiperStatus = "VEHICLEDATA_WIPERSTATUS",
  headLampStatus = "VEHICLEDATA_HEADLAMPSTATUS",
  engineTorque = "VEHICLEDATA_ENGINETORQUE",
  engineOilLife = "VEHICLEDATA_ENGINEOILLIFE",
  accPedalPosition = "VEHICLEDATA_ACCPEDAL",
  steeringWheelAngle = "VEHICLEDATA_STEERINGWHEEL",
  eCallInfo = "VEHICLEDATA_ECALLINFO",
  airbagStatus = "VEHICLEDATA_AIRBAGSTATUS",
  emergencyEvent = "VEHICLEDATA_EMERGENCYEVENT",
  clusterModeStatus = "VEHICLEDATA_CLUSTERMODESTATUS",
  myKey = "VEHICLEDATA_MYKEY"
}

local requestParams = { }
local responseUiParams = { }
local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
}

--[[ Local Functions ]]
local function setVDRequest()
  local tmp = {}
  for k, _ in pairs(VDValues) do
    tmp[k] = true
  end
  return tmp
end

local function setVDResponse()
  local temp = { }
  local vehicleDataResultCodeValue = "SUCCESS"
  for key, value in pairs(VDValues) do
    local paramName = "clusterModeStatus" == key and "clusterModes" or key
      temp[paramName] = {
        resultCode = vehicleDataResultCodeValue,
        dataType = value
      }
  end
  return temp
end

local function subscribeVD(pParams, self)
  pParams.requestParams = setVDRequest()
  local cid = self.mobileSession1:SendRPC("SubscribeVehicleData", pParams.requestParams)
  pParams.responseUiParams = setVDResponse()
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData", pParams.requestParams)
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", pParams.responseUiParams)
  end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  self.mobileSession1:ExpectNotification("OnHashChange")
end

local function unsubscribeVD(pParams, self)
  local cid = self.mobileSession1:SendRPC("UnsubscribeVehicleData", pParams.requestParams)
  EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", pParams.requestParams)
  :Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", pParams.responseUiParams)
  end)
  local MobResp = commonSmoke.cloneTable(pParams.responseUiParams)
  MobResp.success = true
  MobResp.resultCode = "SUCCESS"
  self.mobileSession1:ExpectResponse(cid, MobResp)
  self.mobileSession1:ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("SubscribeVehicleData", subscribeVD, { allParams })

runner.Title("Test")
runner.Step("UnsubscribeVehicleData Positive Case", unsubscribeVD, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
