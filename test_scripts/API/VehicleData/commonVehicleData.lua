---------------------------------------------------------------------------------------------------
-- VehicleData common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local sdl = require("SDL")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local m = {}

m.allVehicleData = {
  gps = {
    value = {
      longitudeDegrees = 100,
      latitudeDegrees = 20.5,
      utcYear = 2020,
      utcMonth = 6,
      utcDay = 3,
      utcHours = 14,
      utcMinutes = 4,
      utcSeconds = 34,
      pdop = 10,
      hdop = 100,
      vdop = 500,
      actual = false,
      compassDirection = "WEST",
      dimension = "2D",
      satellites = 5,
      altitude = 10,
      heading = 100.9,
      speed = 40.5
    },
    type = "VEHICLEDATA_GPS"
  },
  speed = {
    value = 30.2,
    type = "VEHICLEDATA_SPEED"
  },
  rpm = {
    value = 10,
    type = "VEHICLEDATA_RPM"
  },
  fuelLevel = {
    value = -3,
    type = "VEHICLEDATA_FUELLEVEL"
  },
  fuelLevel_State = {
    value = "NORMAL",
    type = "VEHICLEDATA_FUELLEVEL_STATE"
  },
  instantFuelConsumption = {
    value = 1000.1,
    type = "VEHICLEDATA_FUELCONSUMPTION"
  },
  fuelRange = {
    value = { { type = "GASOLINE" , range = 20 }, { type = "BATTERY", range = 100 } },
    type = "VEHICLEDATA_FUELRANGE"
  },
  externalTemperature = {
    value = 24.1,
    type = "VEHICLEDATA_EXTERNTEMP"
  },
  turnSignal = {
    value = "OFF",
    type = "VEHICLEDATA_TURNSIGNAL"
  },
  vin = {
    value = "SJFHSIGD4058569",
    type = "VEHICLEDATA_VIN"
  },
  prndl = {
    value = "PARK",
    type = "VEHICLEDATA_PRNDL"
  },
  tirePressure = {
    value = {
      pressureTelltale = "OFF",
      leftFront = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      },
      rightFront = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      },
      leftRear = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      },
      rightRear = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      },
      innerLeftRear = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      },
      innerRightRear = {
        status = "NORMAL",
        tpms = "UNKNOWN",
        pressure = 1000
      }
    },
    type = "VEHICLEDATA_TIREPRESSURE"
  },
  odometer = {
    value = 10000,
    type = "VEHICLEDATA_ODOMETER"
  },
  beltStatus = {
    value = {
      driverBeltDeployed = "NO_EVENT",
      passengerBeltDeployed = "NO_EVENT",
      passengerBuckleBelted = "NO_EVENT",
      driverBuckleBelted = "NO_EVENT",
      leftRow2BuckleBelted = "YES",
      passengerChildDetected = "YES",
      rightRow2BuckleBelted = "YES",
      middleRow2BuckleBelted = "NO",
      middleRow3BuckleBelted = "NO",
      leftRow3BuckleBelted = "NOT_SUPPORTED",
      rightRow3BuckleBelted = "NOT_SUPPORTED",
      leftRearInflatableBelted = "NOT_SUPPORTED",
      rightRearInflatableBelted = "FAULT",
      middleRow1BeltDeployed = "NO_EVENT",
      middleRow1BuckleBelted = "NO_EVENT"
    },
    type = "VEHICLEDATA_BELTSTATUS"
  },
  bodyInformation = {
    value = {
      parkBrakeActive = true,
      ignitionStableStatus = "IGNITION_SWITCH_STABLE",
      ignitionStatus = "RUN",
      driverDoorAjar = true,
      passengerDoorAjar = false,
      rearLeftDoorAjar = false,
      rearRightDoorAjar = false
    },
    type = "VEHICLEDATA_BODYINFO"
  },
  deviceStatus = {
    value = {
      voiceRecOn = true,
      btIconOn = false,
      callActive = false,
      phoneRoaming = true,
      textMsgAvailable = false,
      battLevelStatus = "NOT_PROVIDED",
      stereoAudioOutputMuted = false,
      monoAudioOutputMuted = false,
      signalLevelStatus = "NOT_PROVIDED",
      primaryAudioSource = "CD",
      eCallEventActive = false
    },
    type = "VEHICLEDATA_DEVICESTATUS"
  },
  driverBraking = {
    value = "NO_EVENT",
    type = "VEHICLEDATA_BRAKING"
  },
  wiperStatus = {
    value = "AUTO_OFF",
    type = "VEHICLEDATA_WIPERSTATUS"
  },
  headLampStatus = {
    value = {
      ambientLightSensorStatus = "NIGHT",
      highBeamsOn = true,
      lowBeamsOn = false
    },
    type = "VEHICLEDATA_HEADLAMPSTATUS"
  },
  engineTorque = {
    value = 24.5,
    type = "VEHICLEDATA_ENGINETORQUE"
  },
  accPedalPosition = {
    value = 10,
    type = "VEHICLEDATA_ACCPEDAL"
  },
  steeringWheelAngle = {
    value = -100,
    type = "VEHICLEDATA_STEERINGWHEEL"
  },
  engineOilLife = {
    value = 10.5,
    type = "VEHICLEDATA_ENGINEOILLIFE"
  },
  electronicParkBrakeStatus = {
    value = "OPEN",
    type = "VEHICLEDATA_ELECTRONICPARKBRAKESTATUS"
  },
  cloudAppVehicleID = {
    value = "GHF5848363FGHY90034847",
    type = "VEHICLEDATA_CLOUDAPPVEHICLEID"
  },
  eCallInfo = {
    value = {
      eCallNotificationStatus = "NOT_USED",
      auxECallNotificationStatus = "NOT_USED",
      eCallConfirmationStatus = "NORMAL"
    },
    type = "VEHICLEDATA_ECALLINFO"
  },
  airbagStatus = {
    value = {
      driverAirbagDeployed = "NO_EVENT",
      driverSideAirbagDeployed = "NO_EVENT",
      driverCurtainAirbagDeployed = "NO_EVENT",
      passengerAirbagDeployed = "NO_EVENT",
      passengerCurtainAirbagDeployed = "NO_EVENT",
      driverKneeAirbagDeployed = "NO_EVENT",
      passengerSideAirbagDeployed = "NO_EVENT",
      passengerKneeAirbagDeployed = "NO_EVENT"
    },
    type = "VEHICLEDATA_AIRBAGSTATUS"
  },
  emergencyEvent = {
    value = {
      emergencyEventType = "NO_EVENT",
      fuelCutoffStatus = "NORMAL_OPERATION",
      rolloverEvent = "NO",
      maximumChangeVelocity = 0,
      multipleEvents = "NO"
    },
    type = "VEHICLEDATA_EMERGENCYEVENT"
  },
  clusterModeStatus = {
    value = {
      powerModeActive = true,
      powerModeQualificationStatus = "POWER_MODE_OK",
      carModeStatus = "NORMAL",
      powerModeStatus = "KEY_APPROVED_0"
    },
    type = "VEHICLEDATA_CLUSTERMODESTATUS"
  },
  stabilityControlsStatus = {
    value = {
      escSystem = "ON",
      trailerSwayControl = "OFF"
    },
    type = "VEHICLEDATA_STABILITYCONTROLSSTATUS"
  },
  myKey = {
    value = { e911Override = "ON" },
    type = "VEHICLEDATA_MYKEY"
  }
}

m.EMPTY_ARRAY = actions.json.EMPTY_ARRAY

--[[ Shared Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.start = actions.start
m.activateApp = actions.activateApp
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.registerApp = actions.registerApp
m.registerAppWOPTU = actions.registerAppWOPTU
m.policyTableUpdate = actions.policyTableUpdate
m.getConfigAppParams = actions.getConfigAppParams
m.wait = utils.wait
m.extendedPolicy = sdl.buildOptions.extendedPolicy
m.setSDLIniParameter = actions.setSDLIniParameter
m.cloneTable = utils.cloneTable
m.cprint = utils.cprint
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT

--[[ Common Functions ]]
local function getVDParams()
  local out = {}
  for k in pairs(m.allVehicleData) do
    table.insert(out, k)
  end
  return out
end

function m.ptUpdate(pTbl)
  pTbl.policy_table.app_policies[m.getConfigAppParams().fullAppID].groups = { "Base-4", "Emergency-1" }
  local grp = pTbl.policy_table.functional_groupings["Emergency-1"]
  for _, v in pairs(grp.rpcs) do
    v.parameters = getVDParams()
  end
  pTbl.policy_table.vehicle_data = nil
end

function m.ptUpdateMin(pTbl)
  pTbl.policy_table.app_policies[m.getConfigAppParams().fullAppID].groups = { "Base-4", "Emergency-1" }
  local grp = pTbl.policy_table.functional_groupings["Emergency-1"]
  for _, v in pairs(grp.rpcs) do
    v.parameters = {
      "gps"
    }
  end
  pTbl.policy_table.vehicle_data = nil
end

function m.processRPCSubscriptionSuccess(pRpcName, pData)
  local reqParams = {
    [pData] = true
  }
  local respData
  if pData == "clusterModeStatus" then
    respData = "clusterModes"
  else
    respData = pData
  end
  local hmiResParams = {
    [respData] = {
      resultCode = "SUCCESS",
      dataType = m.allVehicleData[pData].type
    }
  }
  local cid = m.getMobileSession():SendRPC(pRpcName, reqParams)
  m.getHMIConnection():ExpectRequest("VehicleInfo." .. pRpcName, reqParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResParams)
    end)
  local mobResParams = m.cloneTable(hmiResParams)
  mobResParams.success = true
  mobResParams.resultCode = "SUCCESS"
  m.getMobileSession():ExpectResponse(cid, mobResParams)
end

function m.checkNotificationSuccess(pData)
  local hmiNotParams = { [pData] = m.allVehicleData[pData].value }
  local mobNotParams = m.cloneTable(hmiNotParams)
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
  m.getMobileSession():ExpectNotification("OnVehicleData", mobNotParams)
end

function m.checkNotificationIgnored(pData)
  local hmiNotParams = { [pData] = m.allVehicleData[pData].value }
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
  m.getMobileSession():ExpectNotification("OnVehicleData")
  :Times(0)
end

function m.updatePreloadedFile(pUpdateFunc)
  local pt = m.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  pUpdateFunc(pt)
  m.setPreloadedPT(pt)
end

function m.processGetVDsuccess(pData)
  local reqParams = {
     [pData] = true
  }
  local hmiResParams = {
    [pData] = m.allVehicleData[pData].value
  }
  local cid = m.getMobileSession():SendRPC("GetVehicleData", reqParams)
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", reqParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResParams)
    end)
  local mobResParams = m.cloneTable(hmiResParams)
  mobResParams.success = true
  mobResParams.resultCode = "SUCCESS"
  m.getMobileSession():ExpectResponse(cid, mobResParams)
end

function m.processGetVDunsuccess(pData)
  local reqParams = {
     [pData] = true
  }
  local cid = m.getMobileSession():SendRPC("GetVehicleData", reqParams)
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", reqParams) :Times(0)
  m.getMobileSession():ExpectResponse(cid, { resultCode = "INVALID_DATA", success = false })
end

function m.processGetVDwithCustomDataSuccess()
  local cid = m.getMobileSession():SendRPC("GetVehicleData", { custom_vd_item1_integer =  true })
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { OEM_REF_INT = true })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { OEM_REF_INT = 10 })
    end)
  local mobResParams = { custom_vd_item1_integer = 10 }
  mobResParams.success = true
  mobResParams.resultCode = "SUCCESS"
  m.getMobileSession():ExpectResponse(cid, mobResParams)
end

return m
