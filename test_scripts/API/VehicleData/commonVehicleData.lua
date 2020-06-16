---------------------------------------------------------------------------------------------------
-- VehicleData common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local sdl = require("SDL")
local events = require("events")

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
m.getHMIAppId = actions.getHMIAppId

--[[ Common Functions ]]

function m.getVDParams()
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
    v.parameters = m.getVDParams()
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

function m.getSubscribeVehicleDataHmiResponse(pResult, pName)
  return { resultCode = pResult, dataType = m.allVehicleData[pName].type }
end

local function buildHmiResponseWithResulCode(pHmiResponse, pResultCode)
  return {
    data = pHmiResponse,
    resultCode = pResultCode
  }
end

local function buildSubscriptionRpcParams(pVdItems)
  local requestParams = {}
  local responseParams = {}
  for _, item in pairs(pVdItems) do
    requestParams[item] = true
    local paramName = item
    if item == "clusterModeStatus" then
      paramName = "clusterModes"
    end
    responseParams[paramName] = {
      resultCode = "SUCCESS",
      dataType = m.allVehicleData[item].type
    }
  end
  local mobileResponseParams = m.cloneTable(responseParams)
  mobileResponseParams.success = true
  mobileResponseParams.resultCode = "SUCCESS"
  return {
    mobileRequest = requestParams,
    hmiRequest = m.cloneTable(requestParams),
    hmiResponse = responseParams,
    mobileResponse = mobileResponseParams
  }
end

local function processVehicleDataRpc(pRpcName, pMobileRequest, pHmiRequest, pHmiResponse, pMobileResponse, pAppid)
  pAppid = pAppid or 1
  pHmiRequest = pHmiRequest or {}
  local mobileSession = m.getMobileSession(pAppid)
  local hmiConnection = m.getHMIConnection()
  local cid = mobileSession:SendRPC(pRpcName, pMobileRequest)
  hmiConnection:ExpectRequest("VehicleInfo." .. pRpcName, pHmiRequest)
  :Times(next(pHmiRequest) and 1 or 0)
  :Do(function(_, data)
      hmiConnection:SendResponse(data.id, data.method, pHmiResponse.resultCode, pHmiResponse.data)
    end)
  mobileSession:ExpectResponse(cid, pMobileResponse)
end

function m.processSubscribeVD(pMobileRequest, pHmiRequest, pHmiResponse, pMobileResponse)
  local hmiResponse = buildHmiResponseWithResulCode(pHmiResponse, "SUCCESS")
  processVehicleDataRpc("SubscribeVehicleData", pMobileRequest, pHmiRequest, hmiResponse, pMobileResponse)
end

function m.processRPCSubscriptionSuccess(pRpcName, pData)
  if type(pData) ~= "table" then pData = { pData } end
  local params = buildSubscriptionRpcParams(pData)
  local hmiResponse = buildHmiResponseWithResulCode(params.hmiResponse, "SUCCESS")
  processVehicleDataRpc(pRpcName, params.mobileRequest, params.hmiRequest, hmiResponse, params.mobileResponse)
  m.getMobileSession():ExpectNotification("OnHashChange")
  :Do(function(_, data)
      m.hashId = data.payload.hashID
    end)
end

function m.processRPCSubscriptionDisallowed(pRpcName, pData)
  local params = buildSubscriptionRpcParams({ pData })
  local mobileResponse = {}
  mobileResponse.resultCode = "DISALLOWED"
  mobileResponse.success = false
  processVehicleDataRpc(pRpcName, params.mobileRequest, nil, nil, mobileResponse)
  m.getMobileSession():ExpectNotification("OnHashChange") :Times(0)
end

function m.processRPCSubscriptionIgnored(pRpcName, pData)
  local params = buildSubscriptionRpcParams({ pData })
  local mobileResponse = {}
  mobileResponse.resultCode = "IGNORED"
  mobileResponse.success = false
  processVehicleDataRpc(pRpcName, params.mobileRequest, nil, nil, mobileResponse)
  m.getMobileSession():ExpectNotification("OnHashChange") :Times(0)
end

function m.processRPCSubscriptionGenericError(pRpcName, pReqParams, pHmiResParams)
  local params = buildSubscriptionRpcParams(pReqParams)
  local mobileResponse = {}
  mobileResponse.resultCode = "GENERIC_ERROR"
  mobileResponse.success = false
  local hmiResponse = buildHmiResponseWithResulCode(pHmiResParams, "SUCCESS")
  processVehicleDataRpc(pRpcName, params.mobileRequest, params.hmiRequest, hmiResponse, mobileResponse)
  m.getMobileSession():ExpectNotification("OnHashChange") :Times(0)
end

function m.checkNotificationSuccess(pData)
  if type(pData) ~= "table" then pData = { pData } end
  local hmiNotParams = {}
  for _, item in pairs(pData) do
    hmiNotParams[item] = m.allVehicleData[item].value
  end
  local mobNotParams = m.cloneTable(hmiNotParams)
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
  m.getMobileSession():ExpectNotification("OnVehicleData", mobNotParams)
end

function m.checkNotificationIgnored(pData)
  if type(pData) ~= "table" then pData = { pData } end
  local hmiNotParams = {}
  for _, item in pairs(pData) do
    hmiNotParams[item] = m.allVehicleData[item].value
  end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
  m.getMobileSession():ExpectNotification("OnVehicleData")
  :Times(0)
end

function m.checkNotificationPartiallyIgnored(pAllowedData, pDisallowedData)
  local hmiNotParams = {}
  for _, item in pairs(pAllowedData) do
    hmiNotParams[item] = m.allVehicleData[item].value
  end
  for _, item in pairs(pDisallowedData) do
    hmiNotParams[item] = m.allVehicleData[item].value
  end
  local mobNotParams = {}
  for _, item in pairs(pAllowedData) do
    mobNotParams[item] = m.allVehicleData[item].value
  end
  m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", hmiNotParams)
  m.getMobileSession():ExpectNotification("OnVehicleData", mobNotParams)
end

function m.updatePreloadedFile(pUpdateFunc)
  local pt = m.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
  pUpdateFunc(pt)
  m.setPreloadedPT(pt)
end

function m.processGetVDBaseSuccess(pReqParams, pExpectReqParams, pHmiResParams, pInfo)
  local hmiResponse = buildHmiResponseWithResulCode(pHmiResParams, "SUCCESS")
  local mobileResponse = m.cloneTable(pHmiResParams)
  mobileResponse.success = true
  mobileResponse.resultCode = "SUCCESS"
  if pInfo then
    mobileResponse.info = pInfo
  end
  processVehicleDataRpc("GetVehicleData", pReqParams, pExpectReqParams, hmiResponse, mobileResponse)
end

function m.processGetVDsuccess(pData, pHmiResParams)
  pHmiResParams = pHmiResParams or m.allVehicleData[pData]

  local hmiResParams = {
    [pData] = pHmiResParams.value
  }
  local reqParams = {
    [pData] = true
  }
  m.processGetVDBaseSuccess(reqParams, reqParams, hmiResParams)
end

function m.processGetVDsuccessManyParameters( ... )
  local reqParams = {}
  local hmiResParams = {}

  for _, vehicleData in ipairs( { ... } ) do
    reqParams[vehicleData] = true
    hmiResParams[vehicleData] = m.allVehicleData[vehicleData].value
  end
  m.processGetVDBaseSuccess(reqParams, reqParams, hmiResParams)
end

function m.processGetVDsuccessCutDisallowedParameters(pDisallowedData, pAllowedData)
  local reqParams = {
    [pDisallowedData] = true,
    [pAllowedData] = true
  }
  local expectReqParams = {
    [pAllowedData] = true
  }
  local hmiResParams = {
    [pAllowedData] = m.allVehicleData[pAllowedData].value
  }

  local info = '\'' .. pDisallowedData .. '\'' ..  " disallowed by policies."
  m.processGetVDBaseSuccess(reqParams, expectReqParams, hmiResParams, info)
end

function m.processGetVDunsuccess(pData, pResultCode)
  pResultCode = pResultCode or "INVALID_DATA"

  local reqParams = {
     [pData] = true
  }

  local cid = m.getMobileSession():SendRPC("GetVehicleData", reqParams)
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", reqParams) :Times(0)
  m.getMobileSession():ExpectResponse(cid, { resultCode = pResultCode, success = false })
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

function m.processGetVDGenericError(pReqParams, pHmiResParams)
  local cid = m.getMobileSession():SendRPC("GetVehicleData", pReqParams)
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", pReqParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", pHmiResParams)
    end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

function m.hmiLeveltoLimited(pAppId, pSystemContext)
  pAppId = pAppId or 1
  pSystemContext = pSystemContext or "MAIN"
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = m.getHMIAppId(pAppId) })
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = pSystemContext })
end

function m.hmiLeveltoBackground(pAppId, pSystemContext)
  pAppId = pAppId or 1
  pSystemContext = pSystemContext or "MAIN"
  m.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "AUDIO_SOURCE", isActive = true })
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = pSystemContext })
end

function m.ignitionOff()
  local hmiConnection = actions.hmi.getConnection()
  local mobileConnection = actions.mobile.getConnection()
  config.ExitOnCrash = false
  local timeout = 5000
  local function removeSessions()
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.deleteSession(i)
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  mobileConnection:ExpectEvent(event, "SDL shutdown")
  :Do(function()
    removeSessions()
    StopSDL()
    config.ExitOnCrash = true
  end)
  hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  hmiConnection:ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.getSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end
  end)
  hmiConnection:ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(actions.mobile.getAppsCount())
  local isSDLShutDownSuccessfully = false
  hmiConnection:ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
    utils.cprint(35, "SDL was shutdown successfully")
    isSDLShutDownSuccessfully = true
    mobileConnection:RaiseEvent(event, event)
  end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      mobileConnection:RaiseEvent(event, event)
    end
  end
  actions.run.runAfter(forceStopSDL, timeout + 500)
end

return m
