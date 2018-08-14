---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2380
--
-- Precondition:
-- (OnVehicleData) PoliciesManager must allow all requested params in case "parameters" field is omited
-- Description:
-- Steps to reproduce:
-- 1) SDL receives OnVehicleData notification from HMI
-- 2) And this notification is allowed by Policies for this mobile app
-- 3) And "parameters" field is omited at PolicyTable for this notification
-- Expected:
-- 1) Transfer received notification with all parameters as is to mobile app
-- 2) Respond with <received_resultCode_from_HMI> to mobile app
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local variables ]]
local onVehicleNotification = {
  speed = 10,
	fuelLevel = 12.000000,
	instantFuelConsumption = 5.000000,
	externalTemperature = -40.000000,
	engineTorque = 1000.000000,
	accPedalPosition = 3.000000,
	steeringWheelAngle = 2000.000000,
  rpm = 1,
  electronicParkBrakeStatus = "CLOSED",
  turnSignal = "OFF",
  odometer = 700,
  engineOilLife = 55.5,
  fuelRange = {
    {
      type = "GASOLINE",
      range = 400.5
    }
  },
	vin = "a",
	prndl = "PARK",
	fuelLevel_State = "UNKNOWN",
	driverBraking = "NO_EVENT",
	wiperStatus = "OFF",
  headLampStatus = {	
    lowBeamsOn = false, 
		highBeamsOn = false, 
		ambientLightSensorStatus = "NIGHT"
	},
	deviceStatus = {	
    voiceRecOn = true,
		btIconOn = true,
		callActive = true,
		phoneRoaming = true,
		textMsgAvailable = true,
		stereoAudioOutputMuted = true,
		monoAudioOutputMuted = true,
		eCallEventActive = true,
		primaryAudioSource = "USB",
		battLevelStatus = "ZERO_LEVEL_BARS",
		signalLevelStatus = "ZERO_LEVEL_BARS"
	},				
  bodyInformation = {	
    parkBrakeActive = true, 
    driverDoorAjar = true,
    passengerDoorAjar = true,
    rearLeftDoorAjar = true,
    rearRightDoorAjar = true,
    ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
    ignitionStatus = "UNKNOWN"
  },
  beltStatus ={	
    driverBeltDeployed = "NO_EVENT",
    passengerBeltDeployed = "NO_EVENT",
    passengerBuckleBelted = "NO_EVENT",
    driverBuckleBelted = "NO_EVENT",
    leftRow2BuckleBelted = "NO_EVENT",
    passengerChildDetected = "NO_EVENT",
    rightRow2BuckleBelted = "NO_EVENT",
    middleRow2BuckleBelted = "NO_EVENT",
    middleRow3BuckleBelted = "NO_EVENT",
    leftRow3BuckleBelted = "NO_EVENT",
    rightRow3BuckleBelted = "NO_EVENT",
    leftRearInflatableBelted = "NO_EVENT",
    rightRearInflatableBelted = "NO_EVENT",
    middleRow1BeltDeployed = "NO_EVENT",
    middleRow1BuckleBelted = "NO_EVENT"
  },
  gps =	{	
    longitudeDegrees = -150.0,
    latitudeDegrees = -60.0,
    pdop = 4.0,
    hdop = 5.0,
    vdop = 7.0,
    altitude = -10000.0,
    heading = 5.0,
    speed = 53.0,
    utcYear = 2010,
    utcMonth = 1,
    utcDay = 1,
    utcHours = 0,
    utcMinutes = 3,
    utcSeconds = 5,
    satellites = 1,
    compassDirection = "NORTH",
    dimension = "NO_FIX",
    actual = true
  },
  tirePressure = {
    pressureTelltale = "OFF",
    leftFront = {status = "UNKNOWN"},
    rightFront = {status = "UNKNOWN"},
    leftRear = {status = "UNKNOWN"},
    rightRear = {status = "UNKNOWN"},
    innerLeftRear = {status = "UNKNOWN"},
    innerRightRear = {status = "UNKNOWN"}
  },
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

-- [[ Local Functions ]]
local function pTUpdateFunc(tbl)
  local VDgroup = {
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },    
      },
      OnVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
      }
    }
  }
tbl.policy_table.functional_groupings["NewTestCaseGroup"] = VDgroup
tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups = {"Base-4", "NewTestCaseGroup"}
end

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

local function subscribeVD()
  requestParams = setVDRequest()
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", requestParams)
  responseUiParams = setVDResponse()
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", requestParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseUiParams)
  end)
  local MobResp = responseUiParams
  MobResp.success = true
  MobResp.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function sendOnVehicleData(pParam)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { [pParam] = onVehicleNotification[pParam] })
  common.getMobileSession():ExpectNotification("OnVehicleData", { [pParam] = onVehicleNotification[pParam] })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("RAI, PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("SubscribeVehicleData", subscribeVD)
for k, _ in pairs(VDValues) do 
  runner.Step("Send OnVehicleData " .. k, sendOnVehicleData, { k })
end

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
