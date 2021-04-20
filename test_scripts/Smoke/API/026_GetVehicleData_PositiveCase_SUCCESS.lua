---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: GetVehicleData
-- Item: Happy path
--
-- Requirement summary:
-- [GetVehicleData] SUCCESS: getting SUCCESS:VehicleInfo.GetVehicleData()
--
-- Description:
-- Mobile application sends valid GetVehicleData request and gets VehicleInfo.GetVehicleData "SUCCESS"
-- response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests GetVehicleData with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if VehicleInfo interface is available on HMI
-- SDL checks if GetVehicleData is allowed by Policies
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
local vehicleDataValues = {
  gps = {
    longitudeDegrees = 25.5,
    latitudeDegrees = 45.5,
    utcYear = 2010,
    utcMonth = 1,
    utcDay = 1,
    utcHours = 2,
    utcMinutes = 3,
    utcSeconds = 4,
    compassDirection = "NORTH",
    pdop = 1.1,
    hdop = 2.2,
    vdop = 3.3,
    actual = true,
    satellites = 5,
    dimension = "NO_FIX",
    altitude = 4.4,
    heading = 5.5,
    speed = 100
  },
  speed = 100.5,
  rpm = 1000,
  fuelLevel = 50.5,
  fuelLevel_State = "NORMAL",
  fuelRange = {
    {
      type = "GASOLINE",
      range = 400.5
    }
  },
  instantFuelConsumption = 1000.5,
  externalTemperature = 55.5,
  turnSignal = "OFF",
  vin = "123456",
  prndl = "DRIVE",
  tirePressure = {
    pressureTelltale = "ON",
    leftFront = { status = "NORMAL" },
    rightFront = { status = "NORMAL" },
    leftRear = { status = "NORMAL" },
    rightRear = { status = "NORMAL" },
    innerLeftRear = { status = "NORMAL" },
    innerRightRear = { status = "NORMAL" }
  },
  odometer = 8888,
  beltStatus = {
    driverBeltDeployed = "NOT_SUPPORTED",
    passengerBeltDeployed = "YES",
    passengerBuckleBelted = "YES",
    driverBuckleBelted = "YES",
    leftRow2BuckleBelted = "YES",
    passengerChildDetected = "YES",
    rightRow2BuckleBelted = "YES",
    middleRow2BuckleBelted = "YES",
    middleRow3BuckleBelted = "YES",
    leftRow3BuckleBelted = "YES",
    rightRow3BuckleBelted = "YES",
    leftRearInflatableBelted = "YES",
    rightRearInflatableBelted = "YES",
    middleRow1BeltDeployed = "YES",
    middleRow1BuckleBelted = "YES"
  },
  electronicParkBrakeStatus = "CLOSED",
  bodyInformation = {
    parkBrakeActive = true,
    ignitionStableStatus = "MISSING_FROM_TRANSMITTER",
    ignitionStatus = "UNKNOWN"
  },
  deviceStatus = {
    voiceRecOn = true,
    btIconOn = true,
    callActive = true,
    phoneRoaming = true,
    textMsgAvailable = true,
    battLevelStatus = "ONE_LEVEL_BARS",
    stereoAudioOutputMuted = true,
    monoAudioOutputMuted = true,
    signalLevelStatus = "TWO_LEVEL_BARS",
    primaryAudioSource = "USB",
    eCallEventActive = true
  },
  driverBraking = "NOT_SUPPORTED",
  wiperStatus = "MAN_LOW",
  headLampStatus = {
    lowBeamsOn = true,
    highBeamsOn = true,
    ambientLightSensorStatus = "NIGHT"
  },
  engineTorque = 555.5,
  engineOilLife = 55.5,
  accPedalPosition = 55.5,
  steeringWheelAngle = 555.5,
  eCallInfo = {
    eCallNotificationStatus = "NORMAL",
    auxECallNotificationStatus = "NORMAL",
    eCallConfirmationStatus = "NORMAL"
  },
  airbagStatus = {
    driverAirbagDeployed = "NOT_SUPPORTED",
    driverSideAirbagDeployed = "NOT_SUPPORTED",
    driverCurtainAirbagDeployed = "NOT_SUPPORTED",
    passengerAirbagDeployed = "NOT_SUPPORTED",
    passengerCurtainAirbagDeployed = "NOT_SUPPORTED",
    driverKneeAirbagDeployed = "NOT_SUPPORTED",
    passengerSideAirbagDeployed = "NOT_SUPPORTED",
    passengerKneeAirbagDeployed = "NOT_SUPPORTED"
  },
  emergencyEvent = {
    emergencyEventType = "NO_EVENT",
    fuelCutoffStatus = "NORMAL_OPERATION",
    rolloverEvent = "NO_EVENT",
    maximumChangeVelocity = 0,
    multipleEvents = "NO_EVENT"
  },
  clusterModeStatus = {
    powerModeActive = true,
    powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
    carModeStatus = "TRANSPORT",
    powerModeStatus = "KEY_OUT"
  },
  myKey = {
    e911Override = "NO_DATA_EXISTS"
  }
}

local function setVDRequest()
  local tmp = {}
  for k, _ in pairs(vehicleDataValues) do
    tmp[k] = true
  end
  return tmp
end

local allParams = {
  requestParams = setVDRequest(),
  responseUiParams = vehicleDataValues,
}

--[[ Local Functions ]]
local function getVD(pParams)
  local cid = common.getMobileSession():SendRPC("GetVehicleData", pParams.requestParams)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", pParams.requestParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", pParams.responseUiParams)
    end)
  local mobResp = pParams.responseUiParams
  mobResp.success = true
  mobResp.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, mobResp)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetVehicleData Positive Case", getVD, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
