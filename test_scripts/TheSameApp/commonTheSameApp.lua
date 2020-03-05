---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local utils = require('user_modules/utils')
local actions = require('user_modules/sequences/actions')
local events = require("events")
local constants = require('protocol_handler/ford_protocol_constants')
local hmi_values = require("user_modules/hmi_values")
local rc = require('user_modules/sequences/remote_control')
local SDL = require('SDL')
local runner = require('user_modules/script_runner')

--[[ Conditions to skip tests ]]
if config.defaultMobileAdapterType ~= "TCP" then
  runner.skipTest("Test is applicable only for TCP connection")
end

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Module ]]
local common = actions

--[[ Common Data ]]
common.events      = events
common.frameInfo   = constants.FRAME_INFO
common.frameType   = constants.FRAME_TYPE
common.serviceType = constants.SERVICE_TYPE

--[[ Proxy Functions ]]
common.getDeviceName = utils.getDeviceName
common.getDeviceMAC = utils.getDeviceMAC
common.cloneTable = utils.cloneTable
common.isTableContains = utils.isTableContains
common.setModuleAllocation = rc.state.setModuleAllocation
common.resetModulesAllocationByApp = rc.state.resetModulesAllocationByApp
common.extendedPolicyOption = SDL.buildOptions.extendedPolicy

--[[ Common Functions ]]
function common.start(pHMIParams)
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
  common.init.SDL()
  :Do(function()
      common.init.HMI()
      :Do(function()
          common.init.HMI_onReady(pHMIParams)
          :Do(function()
              common.hmi.getConnection():RaiseEvent(event, "Start event")
            end)
        end)
    end)
  return common.hmi.getConnection():ExpectEvent(event, "Start event")
end

function common.modifyPreloadedPt(pModificationFunc)
  common.sdl.backupPreloadedPT()
  local pt = common.sdl.getPreloadedPT()
  pModificationFunc(pt)
  common.sdl.setPreloadedPT(pt)
end

function common.connectMobDevice(pMobConnId, pDeviceInfo, pIsSDLAllowed)
  if pIsSDLAllowed == nil then pIsSDLAllowed = true end
  utils.addNetworkInterface(pMobConnId, pDeviceInfo.host)
  common.mobile.createConnection(pMobConnId, pDeviceInfo.host, pDeviceInfo.port)
  local mobConnectExp = common.mobile.connect(pMobConnId)
  if pIsSDLAllowed then
    mobConnectExp:Do(function()
        common.mobile.allowSDL(pMobConnId)
      end)
  end
end

function common.deleteMobDevice(pMobConnId)
  utils.deleteNetworkInterface(pMobConnId)
end

function common.connectMobDevices(pDevices)
  for i = 1, #pDevices do
    common.connectMobDevice(i, pDevices[i])
  end
end

function common.clearMobDevices(pDevices)
  for i = 1, #pDevices do
    common.deleteMobDevice(i)
  end
end

function common.registerAppEx(pAppId, pAppParams, pMobConnId, pHasPTU)
  local appParams = common.app.getParams(pAppId)
  for k, v in pairs(pAppParams) do
    appParams[k] = v
  end
  local session = common.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", appParams)
      local connection = session.mobile_session_impl.connection
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        {
          application = {
            appName = appParams.appName,
            deviceInfo = {
              name = common.getDeviceName(connection.host, connection.port),
              id = common.getDeviceMAC(connection.host, connection.port)
            }
          }
        })
      :Do(function(_, d1)
        common.hmi.getConnection():ExpectRequest("VR.ChangeRegistration")
        common.hmi.getConnection():ExpectRequest("TTS.ChangeRegistration")
        common.hmi.getConnection():ExpectRequest("UI.ChangeRegistration")
        common.app.setHMIId(d1.params.application.appID, pAppId)
          if pHasPTU then
            common.isPTUStarted()
          end
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

function common.registerAppExVrSynonyms(pAppId, pAppParams, pMobConnId)
  local appParams = common.app.getParams(pAppId)
  for k, v in pairs(pAppParams) do
    appParams[k] = v
  end

  local session = common.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", appParams)
      local connection = session.mobile_session_impl.connection
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        {
          application = {
            appName = appParams.appName,
            deviceInfo = {
              name = common.getDeviceName(connection.host, connection.port),
              id = common.getDeviceMAC(connection.host, connection.port)
            }
          },
          vrSynonyms = appParams.vrSynonyms
        })
      :Do(function(_, d1)
        common.app.setHMIId(d1.params.application.appID, pAppId)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

function common.registerAppExTtsName(pAppId, pAppParams, pMobConnId)
  local appParams = common.app.getParams(pAppId)
  for k, v in pairs(pAppParams) do
    appParams[k] = v
  end

  local session = common.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", appParams)
      local connection = session.mobile_session_impl.connection
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        {
          application = {
            appName = appParams.appName,
            deviceInfo = {
              name = common.getDeviceName(connection.host, connection.port),
              id = common.getDeviceMAC(connection.host, connection.port)
            }
          },
          ttsName = appParams.ttsName
        })
      :Do(function(_, d1)
        common.app.setHMIId(d1.params.application.appID, pAppId)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

function common.registerAppExNegative(pAppId, pAppParams, pMobConnId, pResultCode)
  local appParams = common.app.getParams(pAppId)
  for k, v in pairs(pAppParams) do
    appParams[k] = v
  end
  local session = common.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", appParams)
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered"):Times(0)
      session:ExpectResponse(corId, { success = false, resultCode = pResultCode })
    end)
end

function common.deactivateApp(pAppId, pNotifParams)
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId(pAppId)})
  common.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus", pNotifParams)
end

function common.exitApp(pAppId)
common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
  { appID = common.getHMIAppId(pAppId), reason = "USER_EXIT"})
common.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus",
  { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

function common.changeRegistrationPositive(pAppId, pParams)
  local cid = common.mobile.getSession(pAppId):SendRPC("ChangeRegistration", pParams)

  common.hmi.getConnection():ExpectRequest("VR.ChangeRegistration", {
    language = pParams.language,
    vrSynonyms = pParams.vrSynonyms,
    appID = common.getHMIAppId(pAppId)
  })
  :Do(function(_, data)
     common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.hmi.getConnection():ExpectRequest("TTS.ChangeRegistration", {
    language = pParams.language,
    ttsName = pParams.ttsName,
    appID = common.getHMIAppId(pAppId)
  })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.hmi.getConnection():ExpectRequest("UI.ChangeRegistration", {
    appName = pParams.appName,
    language = pParams.hmiDisplayLanguage,
    ngnMediaScreenAppName = pParams.ngnMediaScreenAppName,
    appID = common.app.getHMIId(pAppId)
  })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.mobile.getSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function common.changeRegistrationNegative(pAppId, pParams, pResultCode)
  local cid = common.mobile.getSession(pAppId):SendRPC("ChangeRegistration", pParams)
  common.mobile.getSession(pAppId):ExpectResponse(cid, { success = false, resultCode = pResultCode })
  common.hmi.getConnection():ExpectRequest("VR.ChangeRegistration"):Times(0)
  common.hmi.getConnection():ExpectRequest("TTS.ChangeRegistration"):Times(0)
  common.hmi.getConnection():ExpectRequest("UI.ChangeRegistration"):Times(0)
end

function common.mobile.disallowSDL(pMobConnId)
  if pMobConnId == nil then pMobConnId = 1 end
  local connection = common.mobile.getConnection(pMobConnId)
  local event = common.run.createEvent()
  common.hmi.getConnection():SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = false,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(connection.host, connection.port),
      name = utils.getDeviceName(connection.host, connection.port)
    }
  })
  common.run.runAfter(function() common.hmi.getConnection():RaiseEvent(event, "Disallow SDL event") end, 500)
  return common.hmi.getConnection():ExpectEvent(event, "Disallow SDL event")
end

function common.getSystemCapability(pAppId, pResultCode)
  local isSuccess = false
  if pResultCode == "SUCCESS" then
    isSuccess = true
  end

  local mobileSession = common.mobile.getSession(pAppId)
  local cid = mobileSession:SendRPC("GetSystemCapability", { systemCapabilityType = "NAVIGATION" })
  mobileSession:ExpectResponse(cid, {success = isSuccess, resultCode = pResultCode})
end

function common.setProtocolVersion(pProtocolVersion)
  config.defaultProtocolVersion = pProtocolVersion
end

function common.subscribeOnButton(pAppId, pButtonName, pResultCode)
  local isSuccess = false
  if pResultCode == "SUCCESS" then
    isSuccess = true
  end

  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SubscribeButton", {buttonName = pButtonName})
    if pResultCode == "SUCCESS" then
      common.hmi.getConnection():ExpectNotification("Buttons.OnButtonSubscription",
          {name = pButtonName, isSubscribed = true, appID = common.app.getHMIId(pAppId) })
      mobSession:ExpectNotification("OnHashChange")
    end
    mobSession:ExpectResponse(cid, { success = isSuccess, resultCode = pResultCode })
end

function common.sendLocation(pAppId, pResultCode)
  local isSuccess = false
  if pResultCode == "SUCCESS" then
    isSuccess = true
  end

  local mobileSession = common.mobile.getSession(pAppId)
  local corId = mobileSession:SendRPC("SendLocation", {
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1
    })
  if pResultCode == "SUCCESS" then
    common.hmi.getConnection():ExpectRequest("Navigation.SendLocation")
    :Do(function(_,data)
        common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
  mobileSession:ExpectResponse(corId, {success = isSuccess , resultCode = pResultCode})
end

function common.show(pAppId, pResultCode)
  local isSuccess = false
  if pResultCode == "SUCCESS" then
    isSuccess = true
  end

  local mobileSession = common.mobile.getSession(pAppId)
  local corId = mobileSession:SendRPC("Show", {mediaClock = "00:00:01", mainField1 = "Show1"})
  if pResultCode == "SUCCESS" then
    common.hmi.getConnection():ExpectRequest("UI.Show")
    :Do(function(_,data)
        common.hmi.getConnection():SendResponse(data.id, "UI.Show", "SUCCESS", {})
      end)
  end
  mobileSession:ExpectResponse(corId, { success = isSuccess, resultCode = pResultCode})
end

function common.addCommand(pAppId, pData, pResultCode)
  if not pResultCode then pResultCode = "SUCCESS" end
  local isSuccess = false
  if pResultCode == "SUCCESS" then
    isSuccess = true
  end

  local mobileSession = common.mobile.getSession(pAppId)
  local corId = mobileSession:SendRPC("AddCommand", pData.mob)
  if pResultCode == "SUCCESS" then
    local hmi = common.hmi.getConnection()
    hmi:ExpectRequest("VR.AddCommand", pData.hmi)
    :Do(function(_,data)
        hmi:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
  mobileSession:ExpectResponse(corId, {success = isSuccess , resultCode = pResultCode})
end

function common.addSubMenu(pAppId, pData, pResultCode)
  if not pResultCode then pResultCode = "SUCCESS" end
  local isSuccess = false
  if pResultCode == "SUCCESS" then
    isSuccess = true
  end

  local mobileSession = common.mobile.getSession(pAppId)
  local corId = mobileSession:SendRPC("AddSubMenu", pData.mob)
  if pResultCode == "SUCCESS" then
    local hmi = common.hmi.getConnection()
    hmi:ExpectRequest("UI.AddSubMenu", pData.hmi)
    :Do(function(_,data)
        hmi:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
  mobileSession:ExpectResponse(corId, {success = isSuccess , resultCode = pResultCode})
end

function common.funcGroupConsentForApp(pPrompts, pAppId)

  local function findFunctionalGroupIds(pAllowedFunctions, pGroupName)
    local ids = {}
    for _, allowedFunc in pairs(pAllowedFunctions) do
      if allowedFunc.name == pGroupName then
        table.insert(ids, allowedFunc.id)
      end
    end
    return ids
  end

  local function addConsentedFunctionsItems(pAllowedFunctions, pPromptItem, rConsentedFunctions)
    local groupIds = findFunctionalGroupIds(pAllowedFunctions, pPromptItem.name)
    if not next(groupIds) then
      common.run.fail("Unknown user consent prompt:" .. pPromptItem.name)
      return
    end
    for _, groupId in ipairs(groupIds) do
      local item = common.cloneTable(pPromptItem)
      item.id = groupId
      table.insert(rConsentedFunctions, item)
    end
  end

  local hmiAppID = nil
  if pAppId then
    hmiAppID = common.app.getHMIId(pAppId)
    if not hmiAppID then
      common.run.fail("Unknown mobile application number:" .. pAppId)
    end
  end

  local corId = common.hmi.getConnection():SendRequest("SDL.GetListOfPermissions", { appID = hmiAppID})
  common.hmi.getConnection():ExpectResponse(corId)
  :Do(function(_,data)
      local consentedFunctions = {}
      for _, promptItem in pairs(pPrompts) do
        addConsentedFunctionsItems(data.result.allowedFunctions, promptItem, consentedFunctions)
      end

      common.hmi.getConnection():SendNotification("SDL.OnAppPermissionConsent",
        {
          appID = hmiAppID,
          source = "GUI",
          consentedFunctions = consentedFunctions
        })
      common.mobile.getSession(pAppId):ExpectNotification("OnPermissionsChange")
    end)
end

local capabilitiesMap = {
  RADIO = "radioControlCapabilities",
  CLIMATE = "climateControlCapabilities",
  SEAT = "seatControlCapabilities",
  AUDIO = "audioControlCapabilities",
  LIGHT = "lightControlCapabilities",
  HMI_SETTINGS = "hmiSettingsControlCapabilities",
  BUTTONS = "buttonCapabilities"
}

function common.getRcCapabilities(pHmiCapabilities)
  local hmiRcCapabilities = pHmiCapabilities.RC.GetCapabilities.params.remoteControlCapability
  local rcCapabilities = {}
  for moduleType, capabilitiesParamName in pairs(capabilitiesMap) do
    rcCapabilities[moduleType] = hmiRcCapabilities[capabilitiesParamName]
  end
  return rcCapabilities
end

function common.startWithRC(pHmiCapabilities)
  local rcCapabilities = common.getRcCapabilities(pHmiCapabilities)
  local state = rc.state.buildDefaultActualModuleState(rcCapabilities)
  rc.state.initActualModuleStateOnHMI(state)
  common.start(pHmiCapabilities)
end

function common.buildHmiRcCapabilities(pCapabilities)
  local hmiParams = hmi_values.getDefaultHMITable()
  hmiParams.RC.IsReady.params.available = true
  local capParams = hmiParams.RC.GetCapabilities.params.remoteControlCapability
  for k, v in pairs(capabilitiesMap) do
    if pCapabilities[k] then
      if pCapabilities[k] ~= "Default" then
        capParams[v] = pCapabilities[k]
      end
    else
      capParams[v] = nil
    end
  end
  return hmiParams
end

function common.getModuleControlData(pModuleType)
  local out = { moduleType = pModuleType }
  if pModuleType == "CLIMATE" then
    out.climateControlData = {
      fanSpeed = 30,
      desiredTemperature = {
        unit = "CELSIUS",
        value = 11.5
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
      hdChannel = 1,
      radioEnable = true,
      hdRadioEnable = true,
    }
  elseif pModuleType == "LIGHT" then
    out.lightControlData = {
      lightState = {
        {
          id = "FRONT_LEFT_HIGH_BEAM",
          status = "ON",
          density = 0.5,
          color = {
            red = 5,
            green = 15,
            blue = 20
          }
        }
      }
    }
  end
  return out
end

local function createAllocationExpectations(pAppId, pModuleType, pRcAppIds, pRcCapabilities)
  if pModuleType == "HMI_SETTINGS" or pModuleType == "LIGHT" then
    common.setModuleAllocation(pModuleType, pRcCapabilities[pModuleType].moduleInfo.moduleId, pAppId)
  else
    common.setModuleAllocation(pModuleType, pRcCapabilities[pModuleType][1].moduleInfo.moduleId, pAppId)
  end
  common.validateOnRCStatus(pRcAppIds)
end

function common.allocateModuleToApp(pAppId, pModuleType, pRcAppIds, pRcCapabilities)
  createAllocationExpectations(pAppId, pModuleType, pRcAppIds, pRcCapabilities)
  common.rpcAllowed(pAppId, pModuleType)
end

function common.allocateModuleToAppWithConsent (pAppId, pModuleType, pRcAppIds, pRcCapabilities)
  createAllocationExpectations(pAppId, pModuleType, pRcAppIds, pRcCapabilities)
  common.rpcAllowedWithConsent(pAppId, pModuleType)
end

function common.validateOnRCStatus(pAppIds)
  if not pAppIds then pAppIds =  {1} end
  local hmiExpDataTable  = { }
  for _, appId in pairs(pAppIds) do
    local rcStatusForApp = rc.state.getModulesAllocationByApp(appId)
    hmiExpDataTable[common.getHMIAppId(appId)] = utils.cloneTable(rcStatusForApp)
    rcStatusForApp.allowed = true
    rc.rc.expectOnRCStatusOnMobile(appId, rcStatusForApp)
  end
  rc.rc.expectOnRCStatusOnHMI(hmiExpDataTable)
end

function common.defineRAMode(pAllowed, pAccessMode)
  common.hmi.getConnection():SendNotification("RC.OnRemoteControlSettings",
      {allowed = pAllowed, accessMode = pAccessMode})
  common.run.wait(common.minTimeout) -- workaround due to issue with SDL -> redundant OnHMIStatus notification is sent
end

local function successHmiRequestSetInteriorVehicleData(pAppId, pModuleControlData)
  common.hmi.getConnection():ExpectRequest("RC.SetInteriorVehicleData", {
    appID = common.app.getHMIId(pAppId),
    moduleData = pModuleControlData
  })
  :Do(function(_, data)
      local moduleControlData = common.cloneTable(pModuleControlData)
      moduleControlData.moduleId = data.params.moduleData.moduleId
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = moduleControlData
      })
      common.setModuleAllocation(moduleControlData.moduleType, moduleControlData.moduleId, pAppId)
    end)
end

function common.rpcAllowed(pAppId, pModuleType)
  local moduleControlData = common.getModuleControlData(pModuleType)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {
        moduleData = moduleControlData
      })
  successHmiRequestSetInteriorVehicleData(pAppId, moduleControlData)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function common.rpcAllowedWithConsent(pAppId, pModuleType)
  local moduleControlData = common.getModuleControlData(pModuleType)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {
        moduleData = moduleControlData
      })
  common.hmi.getConnection():ExpectRequest("RC.GetInteriorVehicleDataConsent", {
        appID = common.app.getHMIId(pAppId),
        moduleType = pModuleType
      })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {allowed = { true } })
      successHmiRequestSetInteriorVehicleData(pAppId, moduleControlData)
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function common.rpcDenied(pAppId, pModuleType, pResultCode)
  local moduleControlData = common.getModuleControlData(pModuleType)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {
        moduleData = moduleControlData
      })
  common.hmi.getConnection():ExpectRequest("RC.SetInteriorVehicleData", {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

function common.rpcRejectWithConsent(pAppId, pModuleType)
  local moduleControlData = common.getModuleControlData(pModuleType)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {
        moduleData = moduleControlData
      })
  common.hmi.getConnection():ExpectRequest("RC.GetInteriorVehicleDataConsent", {
        appID = common.app.getHMIId(pAppId),
        moduleType = pModuleType
      })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {allowed = { false } })
      common.hmi.getConnection():ExpectRequest("RC.SetInteriorVehicleData", {}):Times(0)
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED"})
end

function common.ignitionOff(pDevices, pExpFunc)
  config.ExitOnCrash = false
  local isOnSDLCloseSent = false
  local hmi = common.hmi.getConnection()
  if pExpFunc then pExpFunc() end
  hmi:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  hmi:ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      hmi:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      hmi:ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
          isOnSDLCloseSent = true
        end)
      :Times(AtMost(1))
    end)
  common.run.wait(3000)
  :Do(function()
      if isOnSDLCloseSent == false then utils.cprint(35, "BC.OnSDLClose was not sent") end
      common.sdl.stop()
      for i in pairs(pDevices) do
        common.mobile.deleteConnection(i)
      end
      RUN_AFTER(function() config.ExitOnCrash = true end, 500)
    end)
end

function common.reRegisterAppEx(pAppId, pMobConnId, pAppsData, pExpResDataFunc)
  local appData = pAppsData[pAppId]
  local params = common.cloneTable(common.app.getParams(pAppId))
  local hmiAppId

  if appData and type(appData) == "table" then
    params.hashID = appData.hashId
    hmiAppId = appData.hmiAppId
  end

  local session = common.mobile.createSession(pAppId, pMobConnId)
  local connection = session.mobile_session_impl.connection
  session:StartService(7)
  :Do(function()
      if pExpResDataFunc then pExpResDataFunc() end
      local cid = session:SendRPC("RegisterAppInterface", params)
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        {
          application = {
            appName = params.appName,
            appID = hmiAppId,
            deviceInfo = {
              name = common.getDeviceName(connection.host, connection.port),
              id = common.getDeviceMAC(connection.host, connection.port)
            }
          }
        })
      :Do(function(_, d1)
        common.app.setHMIId(d1.params.application.appID, pAppId)
        end)
      session:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    end)
end

function common.unexpectedDisconnect(pAppId)
  if pAppId == nil then pAppId = 1 end
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = true, appID = common.app.getHMIId(pAppId) })
  common.mobile.closeSession(pAppId)
  utils.wait(1000)
end

function common.triggerPTUtoGetPTS()
  local triggerAppParams = common.cloneTable(common.app.getParams(1))
  triggerAppParams.appName = "AppToTriggerPTU"
  triggerAppParams.appID = "trigger"
  triggerAppParams.fullAppID = "fullTrigger"

  local hmi = common.hmi.getConnection()
  local session = common.mobile.createSession(10, 1)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", triggerAppParams)
      hmi:ExpectNotification("BasicCommunication.OnAppRegistered")
      :Do(function(_, _)
          hmi:ExpectRequest("BasicCommunication.PolicyUpdate")
          :Do(function(_, d)
              hmi:SendResponse(d.id, d.method, "SUCCESS", {})
            end)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    end)
end

function common.checkCounter(pPolicyAppID, pCounterName, pExpectedCounterValue)
  local ptsFileName = common.sdl.getSDLIniParameter("SystemFilesPath") .. "/"
    .. common.sdl.getSDLIniParameter("PathToSnapshot")
  if utils.isFileExist(ptsFileName) then
    local pTbl = utils.jsonFileToTable(ptsFileName)
    if pTbl
        and pTbl.policy_table
        and pTbl.policy_table.usage_and_error_counts
        and pTbl.policy_table.usage_and_error_counts.app_level
        and pTbl.policy_table.usage_and_error_counts.app_level[pPolicyAppID] then
      local countersTbl = pTbl.policy_table.usage_and_error_counts.app_level[pPolicyAppID]
      local actualCounterValue = countersTbl[pCounterName]
      if actualCounterValue == pExpectedCounterValue then
        return
      end
      local msg = "Incorrect " .. pCounterName .. " counter value. Expected: "
          .. tostring(pExpectedCounterValue) .. ", actual: " .. tostring(actualCounterValue)
      common.run.fail(msg)
      return
    end
    common.run.fail("PTS is incorrect")
    return
  end
  common.run.fail("PTS file was not found")
end

function common.startVideoService(pAppId)
  local mobSession = common.mobile.getSession(pAppId)
  mobSession:StartService( 11 )
  :ValidIf(function(_, data)
      if data.frameInfo == common.frameInfo.START_SERVICE_ACK then
        print("\t   --> StartService ACK received")
        return true
      else
        print("\t   --> StartService NACK received")
        return false
      end
    end)
  local hmi = common.hmi.getConnection()
  hmi:ExpectNotification("Navigation.StartStream")
    :Do(function(_,data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

function common.startVideoServiceNACK(pAppId)
  local mobSession = common.mobile.getSession(pAppId)
  local sendMessageData = {
    serviceType = common.serviceType.VIDEO,
    frameInfo   = common.frameInfo.START_SERVICE,
    frameType   = common.frameType.CONTROL_FRAME,
    sessionId   = mobSession.SessionId.get()
  }

  local startServiceEvent = common.events.Event()
  startServiceEvent.matches = function(_, data)
    return data.frameType == common.frameType.CONTROL_FRAME and
         data.sessionId == mobSession.SessionId.get() and
         data.serviceType == common.serviceType.VIDEO and
        (data.frameInfo == common.frameInfo.START_SERVICE_NACK or
         data.frameInfo == common.frameInfo.START_SERVICE_ACK)
    end
  local ret = mobSession:ExpectEvent(startServiceEvent, "Expect StartServiceNACK")
  ret:ValidIf(function(_, data)
      if data.frameInfo == common.frameInfo.START_SERVICE_NACK then
        print("\t   --> StartService NACK received")
        return true
      else
        return false, "StartService ACK received"
      end
    end)

  mobSession:Send(sendMessageData)
  return ret
end

function common.sendOnButtonEventPress(pAppId1, pAppId2, pButtonName, pNumberOfDevicesSubscribed)
  local mobSession1 = common.mobile.getSession(pAppId1)
  local mobSession2 = common.mobile.getSession(pAppId2)
  local pTime = pNumberOfDevicesSubscribed

  common.hmi.getConnection():SendNotification("Buttons.OnButtonEvent",
    {name = pButtonName, mode = "BUTTONDOWN", appID = common.app.getHMIId(pAppId1) })
  mobSession1:ExpectNotification("OnButtonEvent",{buttonName = pButtonName, buttonEventMode="BUTTONDOWN"}):Times(pTime)
  mobSession2:ExpectNotification("OnButtonEvent",{buttonName = pButtonName, buttonEventMode="BUTTONDOWN"}):Times(0)
  common.hmi.getConnection():SendNotification("Buttons.OnButtonPress",
    {name = pButtonName, mode = "LONG", appID = common.app.getHMIId(pAppId1)})
  mobSession1:ExpectNotification("OnButtonPress",{buttonName = pButtonName, buttonPressMode = "LONG"}):Times(pTime)
  mobSession2:ExpectNotification("OnButtonPress",{buttonName = pButtonName, buttonPressMode = "LONG"}):Times(0)
end

function common.hmiLeveltoLimited(pAppId)
 common.getHMIConnection(pAppId):SendNotification("BasicCommunication.OnAppDeactivated",
     { appID = common.getHMIAppId(pAppId) })
 common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
   { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

function common.sendSubscribeWayPoints(pAppId, pIsAFirstApp)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SubscribeWayPoints", {})
  local pTime = 0
  if pIsAFirstApp then pTime = 1 end

  -- SDL -> HMI should send this request only when 1st app is subscribing
    common.hmi.getConnection():ExpectRequest("Navigation.SubscribeWayPoints"):Times(pTime)
    :Do(function(_,data)
         common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    mobSession:ExpectNotification("OnHashChange")
end

function common.sendOnWayPointChange(pAppId1, pAppId2, pNumberOfAppsSubscribed, pWayPoints)
  local mobSession1 = common.mobile.getSession(pAppId1)
  local mobSession2 = common.mobile.getSession(pAppId2)
  local pTime1, pTime2

  if     pNumberOfAppsSubscribed == 0 then pTime1 = 0; pTime2 = 0
  elseif pNumberOfAppsSubscribed == 1 then pTime1 = 1; pTime2 = 0
  elseif pNumberOfAppsSubscribed == 2 then pTime1 = 1; pTime2 = 1 end

  common.hmi.getConnection():SendNotification("Navigation.OnWayPointChange", { wayPoints = {pWayPoints} })
  mobSession1:ExpectNotification("OnWayPointChange",{ wayPoints = {pWayPoints} }):Times(pTime1)
  mobSession2:ExpectNotification("OnWayPointChange",{ wayPoints = {pWayPoints} }):Times(pTime2)
end

function common.getInteriorVehicleData(pAppId, pModuleType, pSubscribe, pIsAFirstApp, pReqPayload, pRspPayload)
  local pPayload
  if     pModuleType == "RADIO"   then pPayload = 1
  elseif pModuleType == "CLIMATE" then pPayload = 2
  end

  local moduleId
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("GetInteriorVehicleData", { moduleType = pModuleType, subscribe = pSubscribe })
  -- SDL -> HMI - should send this request only when 1st app get subscribed
  if pIsAFirstApp then
    common.hmi.getConnection():ExpectRequest("RC.GetInteriorVehicleData",
        { moduleType = pModuleType, subscribe = pSubscribe})
    :Do(function(_,data)
        moduleId = data.params.moduleId
        pReqPayload[pPayload].moduleData.moduleId = moduleId
        common.hmi.getConnection():SendResponse( data.id, data.method, "SUCCESS", pReqPayload[pPayload] )
      end)
  end
    pRspPayload[pPayload].moduleData.moduleId = moduleId
    mobSession:ExpectResponse( cid, pRspPayload[pPayload] )
end

function common.onInteriorVehicleData(pAppId1, pAppId2, pNumberOfAppsSubscribed, pModuleType, pNotificationPayload)
  local pPayload
  if     pModuleType == "RADIO"   then pPayload = 1
  elseif pModuleType == "CLIMATE" then pPayload = 2
  end

  local mobSession1 = common.mobile.getSession(pAppId1)
  local mobSession2 = common.mobile.getSession(pAppId2)
  local pTime1, pTime2

  if     pNumberOfAppsSubscribed == 0 then pTime1 = 0; pTime2 = 0
  elseif pNumberOfAppsSubscribed == 1 then pTime1 = 1; pTime2 = 0
  elseif pNumberOfAppsSubscribed == 2 then pTime1 = 1; pTime2 = 1 end

  common.hmi.getConnection():SendNotification("RC.OnInteriorVehicleData", pNotificationPayload[pPayload] )
  mobSession1:ExpectNotification("OnInteriorVehicleData", pNotificationPayload[pPayload] ):Times( pTime1 )
  mobSession2:ExpectNotification("OnInteriorVehicleData", pNotificationPayload[pPayload] ):Times( pTime2 )
end

function common.sendRPCPositive(pAppId, pPrefix, pRPCName, pRPCParams, pRequestParams)
  local pReqParams
  if not pRequestParams then pReqParams = pRPCParams end
  local cid = common.mobile.getSession(pAppId):SendRPC(pRPCName, pRPCParams)
      common.hmi.getConnection():ExpectRequest(pPrefix..pRPCName, pReqParams)
  :Do(function(_, data)
       common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  common.mobile.getSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function common.sendRPCNegative(pAppId, pRPCName, pRPCParameters)
  local cid = common.mobile.getSession(pAppId):SendRPC(pRPCName, pRPCParameters)
  common.mobile.getSession(pAppId):ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

function common.createNewGroup(pAppId, pTestGroupName, pTestGroup, pPolicyTable)
  local pt = pPolicyTable

  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null
  pt.policy_table.functional_groupings[pTestGroupName] = pTestGroup
  pt.policy_table.app_policies[pAppId] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies[pAppId].groups = { pTestGroupName, "Notifications-RC" }
end

function common.registerAppWithPTU(pAppId, pAppParams, pDeviceId)
  common.registerAppEx(pAppId, pAppParams, pDeviceId, true)
  common.hmi.getConnection():ExpectRequest("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(2)
  common.run.wait(2500)
end

function common.isPTUNotStarted()
  if common.extendedPolicyOption == "HTTP" then
    for appNum = 1, common.mobile.getAppsCount() do
      common.mobile.getSession(appNum):ExpectNotification("OnSystemRequest")
      :Times(AtMost(1))
      :ValidIf(function(_, data)
          if data.payload.requestType == "HTTP" then
            return false, "RequestType 'HTTP' is unexpected"
          end
          return true
        end)
    end
  else
    common.hmi.getConnection():ExpectRequest("BasicCommunication.PolicyUpdate"):Times(0)
  end
end

function common.registerAppWithoutPTU(pAppId, pAppParams, pDeviceId)
  common.registerAppEx(pAppId, pAppParams, pDeviceId, false)
  common.isPTUNotStarted()
  common.hmi.getConnection():ExpectRequest("SDL.OnStatusUpdate"):Times(0)
  common.run.wait(2500)
end

return common
