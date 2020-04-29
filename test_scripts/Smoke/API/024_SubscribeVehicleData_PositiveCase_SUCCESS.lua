---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: SubscribeVehicleData
-- Item: Happy path
--
-- Requirement summary:
-- [SubscribeVehicleData] SUCCESS: getting SUCCESS:VehicleInfo.SubscribeVehicleData()
--
-- Description:
-- Mobile application sends valid SubscribeVehicleData request and gets VehicleInfo.SubscribeVehicleData "SUCCESS"
-- response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests SubscribeVehicleData with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if VehicleInfo interface is available on HMI
-- SDL checks if SubscribeVehicleData is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the VehicleInfo part of request with allowed parameters to HMI
-- SDL receives VehicleInfo part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

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
  turnSignal = "VEHICLEDATA_TURNSIGNAL",
  prndl = "VEHICLEDATA_PRNDL",
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

local responseUiParams = { }
local requestParams = { }
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

local function subscribeVD(pParams)
  pParams.requestParams = setVDRequest()
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", pParams.requestParams)
  pParams.responseUiParams = setVDResponse()
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", pParams.requestParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", pParams.responseUiParams)
  end)
  local mobResp = pParams.responseUiParams
  mobResp.success = true
  mobResp.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, mobResp)
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SubscribeVehicleData Positive Case", subscribeVD, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
