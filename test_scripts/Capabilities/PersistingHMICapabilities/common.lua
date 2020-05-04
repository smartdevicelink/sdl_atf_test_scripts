---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local events = require('events')
local runner = require('user_modules/script_runner')
local SDL = require('SDL')
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Shared Functions ]]
local m = {}
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.getHMICapabilitiesFromFile = actions.sdl.getHMICapabilitiesFromFile
m.activateApp = actions.app.activate
m.start = actions.start
m.setSDLIniParameter = actions.sdl.setSDLIniParameter
m.cloneTable = utils.cloneTable
m.getDefaultHMITable = hmi_values.getDefaultHMITable

--[[ Local Variables ]]
local hmiCapCacheFile = SDL.AppStorage.path() .. SDL.INI.get("HMICapabilitiesCacheFile")

--[[ Common Functions ]]
function m.noRequestsGetHMIParams()
  local params = m.getDefaultHMITable()
  params.RC.GetCapabilities.occurrence = 0
  params.UI.GetSupportedLanguages.occurrence = 0
  params.UI.GetCapabilities.occurrence = 0
  params.VR.GetSupportedLanguages.occurrence = 0
  params.VR.GetCapabilities.occurrence = 0
  params.TTS.GetSupportedLanguages.occurrence = 0
  params.TTS.GetCapabilities.occurrence = 0
  params.Buttons.GetCapabilities.occurrence = 0
  params.VehicleInfo.GetVehicleType.occurrence = 0
  params.UI.GetLanguage.occurrence = 0
  params.VR.GetLanguage.occurrence = 0
  params.TTS.GetLanguage.occurrence = 0
  return params
end

function m.noResponseGetHMIParams()
  local hmiCaps = m.getDefaultHMITable()
    hmiCaps.RC.IsReady.params.available = true
    hmiCaps.RC.GetCapabilities = nil
    hmiCaps.UI.IsReady.params.available = true
    hmiCaps.UI.GetSupportedLanguages = nil
    hmiCaps.UI.GetCapabilities = nil
    hmiCaps.VR.IsReady.params.available = true
    hmiCaps.VR.GetSupportedLanguages = nil
    hmiCaps.VR.GetCapabilities = nil
    hmiCaps.TTS.IsReady.params.available = true
    hmiCaps.TTS.GetSupportedLanguages = nil
    hmiCaps.TTS.GetCapabilities = nil
    hmiCaps.Buttons.GetCapabilities = nil
    hmiCaps.VehicleInfo.IsReady.params.available = true
    hmiCaps.VehicleInfo.GetVehicleType = nil
    hmiCaps.UI.GetLanguage = nil
    hmiCaps.VR.GetLanguage = nil
    hmiCaps.TTS.GetLanguage = nil
  return hmiCaps
end

local function errorMessage(pMessage, pActualValue, pExpectedValue)
  local errorMsg = pMessage .. " contains unexpected value\n" ..
    " Expected: " .. utils.toString(pExpectedValue) .. "\n" ..
    " Actual: " .. utils.toString(pActualValue) .. "\n"
  return errorMsg
end

function m.checkContentOfCapabilityCacheFile(pExpHmiCapabilities)
  local expHmiCapabilities
  if not pExpHmiCapabilities then
    expHmiCapabilities = m.getDefaultHMITable()
  else
    expHmiCapabilities = pExpHmiCapabilities
  end
  if SDL.AppStorage.isFileExist(actions.sdl.getSDLIniParameter("HMICapabilitiesCacheFile")) then
    local  cacheTable = utils.jsonFileToTable(hmiCapCacheFile)
    local hmiCheckingParametersMap = {
      UI = {
        GetLanguage = { "language" },
        GetSupportedLanguages = { "languages" },
        GetCapabilities = { "displayCapabilities", "hmiCapabilities", "hmiZoneCapabilities",
        "softButtonCapabilities", "systemCapabilities" ,"audioPassThruCapabilitiesList", "pcmStreamCapabilities"
        }
      },
      VR = {
        GetLanguage = { "language" },
        GetSupportedLanguages = { "languages" },
        GetCapabilities  = { "vrCapabilities" }
      },
      TTS = {
        GetLanguage = { "language" },
        GetSupportedLanguages = { "languages" },
        GetCapabilities = { "prerecordedSpeechCapabilities", "speechCapabilities" }
      },
      Buttons = {
        GetCapabilities = { "capabilities", "presetBankCapabilities" }
      },
      VehicleInfo = {
        GetVehicleType = { "vehicleType" }
      },
      RC = {
        GetCapabilities = { "remoteControlCapability", "seatLocationCapability" }
      }
    }
    local errorMessages = ""
    local function validationCapabilities(pMessage, pActual, pExpect)
      if not utils.isTableEqual(pActual, pExpect) then
        errorMessages = errorMessages .. errorMessage(pMessage, pActual, pExpect)
      end
    end
    for mod, requests  in pairs(hmiCheckingParametersMap) do
      for req, params in pairs(requests) do
        for _, param in ipairs(params) do
          local message = mod .. "." .. param
          local expectedResult = expHmiCapabilities[mod][req].params[param]
          if not cacheTable[mod][param] then
            errorMessages = errorMessages ..
              errorMessage(message, "does not exist", expectedResult)
          else
            if param == "audioPassThruCapabilitiesList" then
              validationCapabilities(message, cacheTable[mod].audioPassThruCapabilitie, expectedResult)
            else
              if param == "remoteControlCapability" then
              for _, buttonCap in ipairs(expectedResult.buttonCapabilities) do
                if buttonCap.moduleInfo.allowMultipleAccess == nil then
                  buttonCap.moduleInfo.allowMultipleAccess = true
                end
              end
              validationCapabilities(message, cacheTable[mod][param], expectedResult)
              else
                validationCapabilities(message, cacheTable[mod][param], expectedResult)
              end
            end
          end
        end
      end
    end
    if string.len(errorMessages) > 0 then
      actions.run.fail(errorMessages)
    end
  else
    actions.run.fail("HMICapabilitiesCacheFile file doesn't exist")
  end
end

function m.updateHMISystemInfo(pVersion)
  local hmiValues = m.getDefaultHMITable()
  hmiValues.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = pVersion,
      language = "EN-US",
      wersCountryCode = "wersCountryCode"
    }
  }
  return hmiValues
end

function m.updatedHMICapabilitiesTable()
  local hmiCapTbl = m.getHMICapabilitiesFromFile()
    table.remove(hmiCapTbl.UI.displayCapabilities.textFields, 1)
    hmiCapTbl.UI.hmiZoneCapabilities = "BACK"
    hmiCapTbl.UI.softButtonCapabilities.imageSupported = false
    hmiCapTbl.UI.audioPassThruCapabilities[1].samplingRate = "RATE_8KHZ"
    hmiCapTbl.UI.pcmStreamCapabilities.samplingRate = "RATE_8KHZ"
    hmiCapTbl.UI.systemCapabilities.navigationCapability.sendLocationEnabled = false
    hmiCapTbl.UI.systemCapabilities.phoneCapability.dialNumberEnabled = false
    hmiCapTbl.UI.systemCapabilities.videoStreamingCapability.maxBitrate = 50000
    table.remove(hmiCapTbl.Buttons.capabilities, 1)
    hmiCapTbl.VehicleInfo.vehicleType.modelYear = 2000
    hmiCapTbl.UI.language = "JA-JP"
    hmiCapTbl.VR.language = "JA-JP"
    hmiCapTbl.TTS.language = "JA-JP"
    hmiCapTbl.VR.vrCapabilities[2] = "TEXT"
    hmiCapTbl.TTS.prerecordedSpeechCapabilities = "NEGATIVE_JINGLE"
    table.remove(hmiCapTbl.RC.remoteControlCapability.buttonCapabilities, 1)
    hmiCapTbl.RC.seatLocationCapability.rows = 1
  return hmiCapTbl
end

function m.updatedHMICapabilitiesFile()
  local hmiCapTbl = m.updatedHMICapabilitiesTable()
  actions.sdl.setHMICapabilitiesToFile(hmiCapTbl)
end

function m.checkIfCapabilityCacheFileExists(pIsShouldExists, pFileName)
  if not pFileName then pFileName = SDL.INI.get("HMICapabilitiesCacheFile") end
  if pIsShouldExists == nil or pIsShouldExists == true then
    if SDL.AppStorage.isFileExist(pFileName) then
      utils.cprint(35, pFileName .. " file was created")
    else
      actions.run.fail("HMICapabilitiesCacheFile file doesn't exist")
    end
  else
    if SDL.AppStorage.isFileExist(pFileName) then
      actions.run.fail("HMICapabilitiesCacheFile file exists")
    end
  end
end

function  m.getSystemCapability(pSystemCapabilityType, pResponseCapabilities)
  local errorMessages = ""
  local mobSession = actions.mobile.getSession()
  local cid = mobSession:SendRPC("GetSystemCapability", { systemCapabilityType = pSystemCapabilityType })
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf(function(_,data)
    for param, value in pairs (pResponseCapabilities) do
      if not data.payload.systemCapability[param] then
        errorMessages = errorMessages ..
          errorMessage(param, "does not exist", value)
      else
        if not utils.isTableEqual(data.payload.systemCapability[param], value) then
          errorMessages = errorMessages ..
            errorMessage(param, data.payload.systemCapability[param], value)
        end
      end
    end
    if string.len(errorMessages) > 0 then
      return false, errorMessages
    else
      return true
    end
  end)
end

function m.changeLanguage(pLanguage)
  local hmiConnection = actions.hmi.getConnection()
  hmiConnection:SendNotification("TTS.OnLanguageChange", { language = pLanguage })
  hmiConnection:SendNotification("VR.OnLanguageChange", { language = pLanguage })
  hmiConnection:SendNotification("UI.OnLanguageChange", { language = pLanguage })
end

function m.checkLanguageCapability(pLanguage)
  local data = utils.jsonFileToTable(hmiCapCacheFile)
  if data.VR.language == pLanguage and data.TTS.language == pLanguage and data.UI.language == pLanguage then
    utils.cprint(35, "Languages were changed")
  else
    actions.run.fail("SDL doesn't updated cache file")
  end
end

function m.updateHMILanguageCapability(pLanguage)
  local hmiValues = m.getDefaultHMITable()
  hmiValues.UI.GetLanguage.params.language = pLanguage
  hmiValues.VR.GetLanguage.params.language = pLanguage
  hmiValues.TTS.GetLanguage.params.language = pLanguage
  return hmiValues
end

function m.registerApp(pAppId, pCapResponse, pMobConnId, hasPTU)
  if not pCapResponse then pCapResponse = {} end
  if not pAppId then pAppId = 1 end
  if not pMobConnId then pMobConnId = 1 end

  local policyModes = {
    P  = "PROPRIETARY",
    EP = "EXTERNAL_PROPRIETARY",
    H  = "HTTP"
  }

  local session = actions.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", actions.app.getParams(pAppId))
      actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = actions.app.getParams(pAppId).appName }})
      :Do(function(_, d1)
          actions.app.setHMIId(d1.params.application.appID, pAppId)
          if hasPTU then
            m.ptu.expectStart()
          end
        end)
      local errorMessages = ""
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :ValidIf(function(_,data)
        for param, value in pairs (pCapResponse) do
          if param == "hmiZoneCapabilities" then
            if not data.payload[param] == value then
              errorMessages = errorMessages ..
                errorMessage(param, data.payload[param], value)
            end
          else
            if not utils.isTableEqual(data.payload[param], value) then
              errorMessages = errorMessages ..
                errorMessage(param, data.payload[param], value)
            end
          end
        end
        if string.len(errorMessages) > 0 then
          return false, errorMessages
        else
          return true
        end
      end)
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
          :Times(AnyNumber())
          local policyMode = SDL.buildOptions.extendedPolicy
          if policyMode == policyModes.P or policyMode == policyModes.EP then
            session:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
          end
        end)
    end)
end

function m.masterReset(pExpFunc)
  local isOnSDLCloseSent = false
  if pExpFunc then pExpFunc() end
  actions.hmi.getConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "MASTER_RESET" })
  actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
    isOnSDLCloseSent = true
    SDL.DeleteFile()
  end)
  :Times(AtMost(1))
  actions.run.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then utils.cprint(35, "BC.OnSDLClose was not sent") end
    if SDL:CheckStatusSDL() == SDL.RUNNING then SDL:StopSDL() end
  end)
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

function m.startWoHMIonReady()
  local event = actions.run.createEvent()
  actions.init.SDL()
  :Do(function()
      actions.init.HMI()
      :Do(function()
          actions.init.connectMobile()
          :Do(function()
              actions.init.allowSDL()
              :Do(function()
                  actions.hmi.getConnection():RaiseEvent(event, "Start event")
                end)
            end)
        end)
    end)
  return actions.hmi.getConnection():ExpectEvent(event, "Start event")
end

function m.registerAppSuspend(pAppId, pCapResponse, pHMIParams, pMobConnId, hasPTU)
  if not pCapResponse then pCapResponse = {} end
  if not pAppId then pAppId = 1 end
  if not pMobConnId then pMobConnId = 1 end

  local timeout = 22000
  local timeRunAfter = 10000
  local isHMIonReady = false
  local policyModes = {
    P  = "PROPRIETARY",
    EP = "EXTERNAL_PROPRIETARY",
    H  = "HTTP"
  }

  local function HMIonReady()
  actions.init.HMI_onReady(pHMIParams)
    :Do(function()
      isHMIonReady = true
      end)
  end
  actions.run.runAfter(HMIonReady, timeRunAfter)

  local session = actions.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", actions.app.getParams(pAppId))
      actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = actions.app.getParams(pAppId).appName }}):Timeout(timeout)
      :Do(function(_, d1)
          actions.app.setHMIId(d1.params.application.appID, pAppId)
          if hasPTU then
            m.ptu.expectStart()
          end
      end)
      local errorMessages = ""
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" }):Timeout(timeout)
      :ValidIf(function(_,data)
        if isHMIonReady == false then
          actions.run.fail("RegisterAppInterface response was received before HMI on ready")
        end

        for param, value in pairs (pCapResponse) do
          if param == "hmiZoneCapabilities" then
            if not data.payload[param] == value then
              errorMessages = errorMessages ..
                errorMessage(param, data.payload[param], value)
            end
          else
            if not utils.isTableEqual(data.payload[param], value) then
              errorMessages = errorMessages ..
                errorMessage(param, data.payload[param], value)
            end
          end
        end
        if string.len(errorMessages) > 0 then
          return false, errorMessages
        else
          return true
        end
      end)
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
          :Times(AnyNumber())
          local policyMode = SDL.buildOptions.extendedPolicy
          if policyMode == policyModes.P or policyMode == policyModes.EP then
            session:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
          end
        end)
    end)
end

function m.connectMobDevice(pMobConnId, pDeviceInfo, pIsSDLAllowed)
  if pIsSDLAllowed == nil then pIsSDLAllowed = true end
  utils.addNetworkInterface(pMobConnId, pDeviceInfo.host)
  actions.mobile.createConnection(pMobConnId, pDeviceInfo.host, pDeviceInfo.port)
  local mobConnectExp = actions.mobile.connect(pMobConnId)
  if pIsSDLAllowed then
    mobConnectExp:Do(function()
        actions.mobile.allowSDL(pMobConnId)
      end)
  end
end

function m.deleteMobDevices(pMobConnId)
  utils.deleteNetworkInterface(pMobConnId)
end

function m.startService(pAppId, pMobConnId)
  actions.mobile.createSession(pAppId, pMobConnId):StartService(7)
end

function m.registerAppsSuspend( pCapResponse, pHMIParams )
  local appSessionId1 = 1 -- mobConnId1
  local appSessionId2 = 2 -- mobConnId1
  local appSessionId3 = 3 -- mobConnId2

  local timeout = 22000
  local timeRunAfter = 10000
  local isHMIonReady = false
  local policyModes = {
    P  = "PROPRIETARY",
    EP = "EXTERNAL_PROPRIETARY",
    H  = "HTTP"
  }

  local function validationCapResponse(pData)
    local errorMessages = ""
    for param, value in pairs (pCapResponse) do
      if param == "hmiZoneCapabilities" then
        if not pData.payload[param] == value then
          errorMessages = errorMessages ..
            errorMessage(param, pData.payload[param], value)
        end
      else
        if not utils.isTableEqual(pData.payload[param], value) then
          errorMessages = errorMessages ..
            errorMessage(param, pData.payload[param], value)
        end
      end
    end
    if string.len(errorMessages) > 0 then
      return false, errorMessages
    else
      return true
    end
  end

  local function processingRAIresponse(pSession, pCorId)
    pSession:ExpectResponse(pCorId, { success = true, resultCode = "SUCCESS" }):Timeout(timeout)
    :ValidIf(function(_,data)
      if isHMIonReady == false then
        actions.run.fail("RegisterAppInterface response was received before HMI on ready")
      end
      return validationCapResponse(data)
    end)
    :Do(function()
        pSession:ExpectNotification("OnHMIStatus",
          { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        pSession:ExpectNotification("OnPermissionsChange")
        :Times(AnyNumber())
        local policyMode = SDL.buildOptions.extendedPolicy
        if policyMode == policyModes.P or policyMode == policyModes.EP then
          pSession:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
        end
      end)
  end

  local function HMIonReady()
    actions.init.HMI_onReady(pHMIParams)
     :Do(function()
        isHMIonReady = true
        end)
  end

  actions.run.runAfter(HMIonReady, timeRunAfter)

  local mobSession1 = actions.mobile.getSession(appSessionId1)
  local mobSession2 = actions.mobile.getSession(appSessionId2)
  local mobSession3 = actions.mobile.getSession(appSessionId3)

  actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
    { application = { appName = actions.app.getParams(appSessionId1).appName }},
    { application = { appName = actions.app.getParams(appSessionId2).appName }},
    { application = { appName = actions.app.getParams(appSessionId3).appName }})
  :Do(function(exp, data)
      if exp.occurences == 1 then
        actions.app.setHMIId(data.params.application.appID, appSessionId1)
      elseif exp.occurences == 2 then
        actions.app.setHMIId(data.params.application.appID, appSessionId2)
      else
        actions.app.setHMIId(data.params.application.appID, appSessionId3)
      end
    end)
  :Timeout(timeout)
  :Times(3)

  local corId1 = mobSession1:SendRPC("RegisterAppInterface",
    actions.app.getParams(appSessionId1))
  local corId2 = mobSession2:SendRPC("RegisterAppInterface",
    actions.app.getParams(appSessionId2))
  local corId3 = mobSession3:SendRPC("RegisterAppInterface",
    actions.app.getParams(appSessionId3))

  processingRAIresponse(mobSession1, corId1)
  processingRAIresponse(mobSession2, corId2)
  processingRAIresponse(mobSession3, corId3)

end

return m
