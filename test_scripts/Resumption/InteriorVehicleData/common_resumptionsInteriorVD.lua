---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require("modules/json")
local test = require("user_modules/dummy_connecttest")
local events = require('events')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.isMediaApplication = false

--[[ Variables ]]
local m = actions
m.modules = { "RADIO", "CLIMATE", "SEAT", "AUDIO", "LIGHT", "HMI_SETTINGS" }
m.hashId = {}
m.cloneTable = utils.cloneTable
m.wait = utils.wait
m.tableToString = utils.tableToString

-- [[ Common Functions ]]
function  m.GetInteriorVehicleData(pModuleType, isSubscribe, hmiReqExpectTimes, hashChangeExpectTimes, pAppId)
  if not pAppId then pAppId = 1 end

  local requestParams = {
    moduleType = pModuleType,
    subscribe = isSubscribe
  }

  local cid = m.getMobileSession(pAppId):SendRPC("GetInteriorVehicleData",requestParams)
  EXPECT_HMICALL("RC.GetInteriorVehicleData", requestParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { moduleData = m.getModuleControlData(pModuleType), isSubscribed = isSubscribe })
    end)
  :Times(hmiReqExpectTimes)
  m.getMobileSession(pAppId):ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", moduleData = m.getModuleControlData(pModuleType), isSubscribed = isSubscribe})

  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_,data)
      m.hashId[pAppId] = data.payload.hashID
    end)
  :Times(hashChangeExpectTimes)
  m.wait(300)
end

function m.getModuleControlData(pModuleType)
  local out = { moduleType = pModuleType }
  if pModuleType == "CLIMATE" then
    out.climateControlData = {
      fanSpeed = 50,
      currentTemperature = {
        unit = "FAHRENHEIT",
        value = 20.1
      },
      desiredTemperature = {
        unit = "CELSIUS",
        value = 10.5
      },
      acEnable = true,
      circulateAirEnable = true,
      autoModeEnable = true,
      defrostZone = "FRONT",
      dualModeEnable = true,
      acMaxEnable = true,
      ventilationMode = "BOTH",
      heatedSteeringWheelEnable = true,
      heatedWindshieldEnable = true,
      heatedRearWindowEnable = true,
      heatedMirrorsEnable = true
    }
  elseif pModuleType == "RADIO" then
    out.radioControlData = {
      frequencyInteger = 1,
      frequencyFraction = 2,
      band = "AM",
      rdsData = {
        PS = "ps",
        RT = "rt",
        CT = "123456789012345678901234",
        PI = "pi",
        PTY = 1,
        TP = false,
        TA = true,
        REG = "US"
      },
      availableHDs = 1,
      hdChannel = 1,
      signalStrength = 5,
      signalChangeThreshold = 10,
      radioEnable = true,
      state = "ACQUIRING",
      hdRadioEnable = true,
      sisData = {
        stationShortName = "Name1",
        stationIDNumber = {
          countryCode = 100,
          fccFacilityId = 100
        },
        stationLongName = "RadioStationLongName",
        stationLocation = {
          longitudeDegrees = 0.1,
          latitudeDegrees = 0.1,
          altitude = 0.1
        },
        stationMessage = "station message"
      }
    }
  elseif pModuleType == "SEAT" then
    out.seatControlData = {
      id = "DRIVER",
      heatingEnabled = true,
      coolingEnabled = true,
      heatingLevel = 50,
      coolingLevel = 50,
      horizontalPosition = 50,
      verticalPosition = 50,
      frontVerticalPosition = 50,
      backVerticalPosition = 50,
      backTiltAngle = 50,
      headSupportHorizontalPosition = 50,
      headSupportVerticalPosition = 50,
      massageEnabled = true,
      massageMode = {
        {
          massageZone = "LUMBAR",
          massageMode = "HIGH"
        },
        {
          massageZone = "SEAT_CUSHION",
          massageMode = "LOW"
        }
      },
      massageCushionFirmness = {
        {
          cushion = "TOP_LUMBAR",
          firmness = 30
        },
        {
          cushion = "BACK_BOLSTERS",
          firmness = 60
        }
      },
      memory = {
        id = 1,
        label = "Label value",
        action = "SAVE"
      }
    }
  elseif pModuleType == "AUDIO" then
    out.audioControlData = {
      source = "AM",
      volume = 50,
      equalizerSettings = {
        {
          channelId = 10,
          channelName = "Channel 1",
          channelSetting = 50
        }
      }
    }
  elseif pModuleType == "LIGHT" then
    out.lightControlData = {
      lightState = {
        {
          id = "FRONT_LEFT_HIGH_BEAM",
          status = "ON",
          density = 0.2,
          color = {
            red = 50,
            green = 150,
            blue = 200
          }
        }
      }
    }
  elseif pModuleType == "HMI_SETTINGS" then
    out.hmiSettingsControlData = {
      displayMode = "DAY",
      temperatureUnit = "CELSIUS",
      distanceUnit = "KILOMETERS"
    }
  end
  return out
end

local function updatePreloadedPT(pCountOfRCApps)
  if not pCountOfRCApps then pCountOfRCApps = 2 end
  local preloadedFile = commonPreconditions:GetPathToSDL()
  .. commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  local preloadedTable = utils.jsonFileToTable(preloadedFile)
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  for i = 1, pCountOfRCApps do
    local appId = config["application" .. i].registerAppInterfaceParams.fullAppID
    preloadedTable.policy_table.app_policies[appId] = m.cloneTable(preloadedTable.policy_table.app_policies.default)
    preloadedTable.policy_table.app_policies[appId].moduleType = m.modules
    preloadedTable.policy_table.app_policies[appId].groups = { "Base-4", "RemoteControl" }
    preloadedTable.policy_table.app_policies[appId].AppHMIType = { "REMOTE_CONTROL" }
    preloadedTable.policy_table.app_policies[appId].AppHMIType = nil
  end
  utils.tableToJsonFile(preloadedTable, preloadedFile)
end

local function backupPreloadedPT()
  local preloadedFile = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  commonPreconditions:BackupFile(preloadedFile)
end

local originPrecondition = actions.preconditions
function m.preconditions(isPreloadedUpdate, pCountOfRCApps)
  if isPreloadedUpdate == nil then isPreloadedUpdate = true end
  originPrecondition()
  if isPreloadedUpdate == true then
    backupPreloadedPT()
    updatePreloadedPT(pCountOfRCApps)
  end
end

local function restorePreloadedPT()
  local preloadedFile = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  commonPreconditions:RestoreFile(preloadedFile)
end

local originPostcondition = actions.postconditions
function m.postconditions()
  originPostcondition()
  restorePreloadedPT()
end

function m.reRegisterApp(pAppId, pCheckResumptionData, pCheckResumptionHMILevel, pResultCode)
  if not pAppId then pAppId = 1 end
  if not pResultCode then pResultCode = "SUCCESS" end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = m.cloneTable(m.getConfigAppParams(pAppId))
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
          application = { appName = m.getConfigAppParams(pAppId).appName }
        })
      mobSession:ExpectResponse(corId, { success = true, resultCode = pResultCode })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
  pCheckResumptionData()
  pCheckResumptionHMILevel(pAppId)
end

function m.resumptionFullHMILevel(pAppId)
  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
  :Times(2)
end

function m.checkModuleResumptionData(pModuleType)
  local requestParams = {
    moduleType = pModuleType,
    subscribe = true
  }
  EXPECT_HMICALL("RC.GetInteriorVehicleData", requestParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { moduleData = m.getModuleControlData(pModuleType)})
    end)
end

function m.unexpectedDisconnect()
  test.mobileConnection:Close()
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Do(function()
      for i = 1, m.getAppsCount() do
        test.mobileSession[i] = nil
      end
    end)
end

function m.unregisterAppInterface(pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("UnregisterAppInterface",{})
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  :Do(function()
      m.cleanSessions(pAppId)
      m.resumptionData[pAppId] = {}
    end)
end

function m.cleanSessions(pAppId)
  if pAppId then
    test.mobileSession[pAppId]:Stop()
    test.mobileSession[pAppId] = nil
  else
    for i = 1, m.getAppsCount() do
      test.mobileSession[i]:Stop()
      test.mobileSession[i] = nil
    end
  end
  utils.wait()
end

function m.connectMobile()
  test.mobileConnection:Connect()
  EXPECT_EVENT(events.connectedEvent, "Connected")
  :Do(function()
      utils.cprint(35, "Mobile connected")
    end)
end

function m.ignitionOff()
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      for i=1, m.getAppsCount() do
        m.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      end
    end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(m.getAppsCount())
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
      m.cleanSessions()
      StopSDL()
    end)
end

function m.reRegisterApps(pCheckResumptionData, pResultCode1stApp, pResultCode2ndApp)
  if not pResultCode1stApp then pResultCode1stApp = "SUCCESS" end
  if not pResultCode2ndApp then pResultCode2ndApp = "SUCCESS" end

  local requestParams1 = m.cloneTable(m.getConfigAppParams(1))
  requestParams1.hashID = m.hashId[1]

  local requestParams2 = m.cloneTable(m.getConfigAppParams(2))
  requestParams2.hashID = m.hashId[2]

  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :Do(function(exp, d1)
      if d1.params.appName == m.getConfigAppParams(1).appName then
        m.setHMIAppId(d1.params.application.appID, 1)
      else
        m.setHMIAppId(d1.params.application.appID, 2)
      end
      if exp.occurences == 1 then
        local corId2 = m.getMobileSession(2):SendRPC("RegisterAppInterface", requestParams2)
        m.getMobileSession(2):ExpectResponse(corId2, { success = true, resultCode = pResultCode2ndApp })
      end
    end)
  :Times(2)

  local corId1 = m.getMobileSession(1):SendRPC("RegisterAppInterface", requestParams1)
  m.getMobileSession(1):ExpectResponse(corId1, { success = true, resultCode = pResultCode1stApp })

  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(2) })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  m.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
  :Times(2)

  m.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
  :Times(2)

  pCheckResumptionData()
  m.wait(3000)
end

function m.openRPCservice(pAppId)
  m.getMobileSession(pAppId):StartService(7)
end

function m.activateApp(pAppId, pAudioStreamingState)
  if not pAppId then pAppId = 1 end
  if not pAudioStreamingState then pAudioStreamingState = "AUDIBLE" end
  local requestId = m.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  m.getHMIConnection():ExpectResponse(requestId)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = pAudioStreamingState, systemContext = "MAIN" })
end

return m
