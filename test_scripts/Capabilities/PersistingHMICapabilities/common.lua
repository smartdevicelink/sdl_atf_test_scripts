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
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Shared Functions ]]
local m = {}
m.Title = runner.Title
m.Step = runner.Step
m.postconditions = actions.postconditions
m.getHMICapabilitiesFromFile = actions.sdl.getHMICapabilitiesFromFile
m.setHMICapabilitiesToFile = actions.sdl.setHMICapabilitiesToFile
m.activateApp = actions.app.activate
m.setSDLIniParameter = actions.sdl.setSDLIniParameter
m.cloneTable = utils.cloneTable

--[[ Overridden Functions ]]
local initHMI_onReady_Orig = test.initHMI_onReady
function test:initHMI_onReady(hmi_table)
  return initHMI_onReady_Orig(self, hmi_table, false)
end

--[[ Common Functions ]]
local function excludeAbsentInMobApiTextFields(pTextFields)
  if type(pTextFields) == "table" then
    local textFieldsToExclude = { "timeToDestination", "turnText", "navigationText", "notificationText" }
    for _, excludeTextFieldName in ipairs(textFieldsToExclude) do
      local isFound = false
      local i = #pTextFields
      repeat
        if pTextFields[i].name == excludeTextFieldName then
          table.remove(pTextFields, i)
          isFound = true
        end
        i = i - 1
      until (isFound or i < 1)
    end
  end
end

function m.checkDefaultMobileAdapterType(pApplicableMobileAdapterTypes)
  if type(pApplicableMobileAdapterTypes) == "table" then
    local isTransportDisallowed = true
    for _, allowedTransportType in pairs(pApplicableMobileAdapterTypes) do
      if config.defaultMobileAdapterType == allowedTransportType then
        isTransportDisallowed = false
        break
      end
    end
    if isTransportDisallowed then
      runner.skipTest("This test is not applicable for " .. config.defaultMobileAdapterType .. " mobile transport")
    end
  end
end

function m.getDefaultHMITable()
  local hmiCaps = hmi_values.getDefaultHMITable()
  excludeAbsentInMobApiTextFields(hmiCaps.UI.GetCapabilities.params.displayCapabilities.textFields)
  hmiCaps.VehicleInfo.GetVehicleData.mandatory = false
  return hmiCaps
end

function m.getHMIParamsWithOutRequests(pParams)
  local params = pParams or m.getDefaultHMITable()
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

function m.getHMIParamsWithDelayResponse(pDelayTime)
  local params = m.getDefaultHMITable()
  local delayTime = pDelayTime or 0
  params.RC.GetCapabilities.delay = delayTime
  params.UI.GetSupportedLanguages.delay = delayTime
  params.UI.GetCapabilities.delay = delayTime
  params.VR.GetSupportedLanguages.delay = delayTime
  params.VR.GetCapabilities.delay = delayTime
  params.TTS.GetSupportedLanguages.delay = delayTime
  params.TTS.GetCapabilities.delay = delayTime
  params.Buttons.GetCapabilities.delay = delayTime
  params.VehicleInfo.GetVehicleType.delay = delayTime
  params.UI.GetLanguage.delay = delayTime
  params.VR.GetLanguage.delay = delayTime
  params.TTS.GetLanguage.delay = delayTime
  return params
end

function m.getHMIParamsWithOutResponse()
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

function m.preconditions()
  actions.preconditions()
  actions.setSDLIniParameter("HMICapabilitiesCacheFile", "hmi_capabilities_cache.json")
end

function m.buildDisplayCapForMobileExp(pDisplayCapabilities)
  local displayCapabilities = pDisplayCapabilities
  displayCapabilities.imageCapabilities = nil  -- no Mobile_API.xml
  displayCapabilities.menuLayoutsAvailable = nil --since 6.0
  excludeAbsentInMobApiTextFields(displayCapabilities.textFields)
  return displayCapabilities
end

function m.buildCapRaiResponse()
  local hmiCapabilities = m.getDefaultHMITable()
  local capRaiResponse = {
    buttonCapabilities = hmiCapabilities.Buttons.GetCapabilities.params.capabilities,
    vehicleType = hmiCapabilities.VehicleInfo.GetVehicleType.params.vehicleType,
    audioPassThruCapabilities = hmiCapabilities.UI.GetCapabilities.params.audioPassThruCapabilitiesList,
    hmiDisplayLanguage =  hmiCapabilities.UI.GetCapabilities.params.language,
    language = hmiCapabilities.VR.GetLanguage.params.language, -- or TTS.language
    pcmStreamCapabilities = hmiCapabilities.UI.GetCapabilities.params.pcmStreamCapabilities,
    hmiZoneCapabilities = { hmiCapabilities.UI.GetCapabilities.params.hmiZoneCapabilities },
    softButtonCapabilities = hmiCapabilities.UI.GetCapabilities.params.softButtonCapabilities,
    displayCapabilities = m.buildDisplayCapForMobileExp(hmiCapabilities.UI.GetCapabilities.params.displayCapabilities),
    vrCapabilities = hmiCapabilities.VR.GetCapabilities.params.vrCapabilities,
    speechCapabilities = hmiCapabilities.TTS.GetCapabilities.params.speechCapabilities,
    prerecordedSpeech = hmiCapabilities.TTS.GetCapabilities.params.prerecordedSpeechCapabilities
  }
  return capRaiResponse
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
  local cacheTable = SDL.HMICapCache.get()
  if cacheTable ~= nil then
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
    local function validateCapabilities(pMessage, pActual, pExpect)
      if not utils.isTableEqual(pActual, pExpect) then
        errorMessages = errorMessages .. errorMessage(pMessage, pActual, pExpect)
      end
    end
    for mod, requests  in pairs(hmiCheckingParametersMap) do
      for req, params in pairs(requests) do
        for _, param in ipairs(params) do
          local message = mod .. "." .. param
          local expectedResult = expHmiCapabilities[mod][req].params[param]
          if param == "audioPassThruCapabilitiesList" then
            validateCapabilities(message, cacheTable[mod].audioPassThruCapabilities, expectedResult)
          else
            if not cacheTable[mod][param] then
              errorMessages = errorMessages ..
                errorMessage(message, "does not exist", expectedResult)
            else
              if param == "remoteControlCapability" then
              for _, buttonCap in ipairs(expectedResult.buttonCapabilities) do
                if buttonCap.moduleInfo.allowMultipleAccess == nil then
                  buttonCap.moduleInfo.allowMultipleAccess = true
                end
              end
              validateCapabilities(message, cacheTable[mod][param], expectedResult)
              else
                validateCapabilities(message, cacheTable[mod][param], expectedResult)
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

function m.updateHMICapabilitiesTable(isRemainData)
  local hmiCapTbl = m.getHMICapabilitiesFromFile()
  if not isRemainData then
    table.remove(hmiCapTbl.UI.displayCapabilities.textFields, 1)
    hmiCapTbl.UI.hmiZoneCapabilities = "BACK"
    hmiCapTbl.UI.softButtonCapabilities.imageSupported = false
    hmiCapTbl.UI.audioPassThruCapabilities[1].samplingRate = "RATE_8KHZ"
    hmiCapTbl.UI.pcmStreamCapabilities.samplingRate = "RATE_8KHZ"
    hmiCapTbl.UI.systemCapabilities.navigationCapability.sendLocationEnabled = false
    hmiCapTbl.UI.systemCapabilities.phoneCapability.dialNumberEnabled = false
    hmiCapTbl.UI.systemCapabilities.videoStreamingCapability.maxBitrate = 50000
    hmiCapTbl.UI.systemCapabilities.driverDistractionCapability.menuLength = 4
    hmiCapTbl.UI.systemCapabilities.driverDistractionCapability.subMenuDepth = 2
    table.remove(hmiCapTbl.Buttons.capabilities, 1)
    hmiCapTbl.VehicleInfo.vehicleType.modelYear = 2000
    hmiCapTbl.UI.language = "JA-JP"
    hmiCapTbl.VR.language = "JA-JP"
    hmiCapTbl.TTS.language = "JA-JP"
    hmiCapTbl.VR.vrCapabilities[2] = "TEXT"
    hmiCapTbl.TTS.prerecordedSpeechCapabilities = { "POSITIVE_JINGLE" }
    table.remove(hmiCapTbl.RC.remoteControlCapability.buttonCapabilities, 1)
    hmiCapTbl.RC.seatLocationCapability.rows = 1
  end
  excludeAbsentInMobApiTextFields(hmiCapTbl.UI.displayCapabilities.textFields)
  return hmiCapTbl
end

function m.updateHMICapabilitiesFile(isRemainData)
  local hmiCapTbl = m.updateHMICapabilitiesTable(isRemainData)
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

function m.checkLanguageCapabilityInCache(pLanguage)
  local data = SDL.HMICapCache.get()
  if data and data.VR and data.VR.language == pLanguage
      and data.TTS and data.TTS.language == pLanguage
      and data.UI and data.UI.language == pLanguage then
    utils.cprint(35, "Languages were changed")
  else
    actions.run.fail("SDL doesn't update cache file")
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
          if not utils.isTableEqual(data.payload[param], value) then
            errorMessages = errorMessages ..
                errorMessage(param, data.payload[param], value)
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

function m.postponedRegisterApp(pAppId, pCapResponse, pMobConnId, hasPTU)
  local RAI_POSTPONE_DELAY = 3000
  actions.run.wait(RAI_POSTPONE_DELAY)
  :Do(function()
      m.registerApp(pAppId, pCapResponse, pMobConnId, hasPTU)
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

function m.start(pHMIParams)
  local hmiParams = pHMIParams or hmi_values.getDefaultHMITable()
  if hmiParams and hmiParams.UI and hmiParams.UI.GetCapabilities
      and hmiParams.UI.GetCapabilities.params.displayCapabilities then
    excludeAbsentInMobApiTextFields(hmiParams.UI.GetCapabilities.params.displayCapabilities.textFields)
  end
  return actions.start(hmiParams)
end

local function incompleteStart(isConnectMobile)
  local event = actions.run.createEvent()
  actions.init.SDL()
  :Do(function()
      local initHmiExp = actions.init.HMI()
      if isConnectMobile then
        initHmiExp:Do(function()
            actions.init.connectMobile()
            :Do(function()
                actions.init.allowSDL()
                :Do(function()
                    actions.hmi.getConnection():RaiseEvent(event, "Start event")
                  end)
              end)
          end)
      else
        initHmiExp:Do(function()
            actions.hmi.getConnection():RaiseEvent(event, "Start event")
        end)
      end
    end)
  return actions.hmi.getConnection():ExpectEvent(event, "Start event")
end

function m.startWoHMIonReady()
  return incompleteStart(true)
end

function m.startWoBothHMIonReadyAndMobile()
  return incompleteStart(false)
end

local function registerAppOnEvent(pEvent, pParams, pHmiOnReadyData)
  local policyModes = {
    P  = "PROPRIETARY",
    EP = "EXTERNAL_PROPRIETARY",
    H  = "HTTP"
  }

  actions.hmi.getConnection():ExpectEvent(pEvent, "Event")
  :Do(function()
    local session = actions.mobile.createSession(pParams.appId, pParams.mobConnId)
    session:StartService(7)
    :Do(function()
        local corId = session:SendRPC("RegisterAppInterface", actions.app.getParams(pParams.appId))
        actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
          { application = { appName = actions.app.getParams(pParams.appId).appName }}):Timeout(pParams.timeout)
        :Do(function(_, d1)
            actions.app.setHMIId(d1.params.application.appID, pParams.appId)
            if pParams.hasPTU then
              m.ptu.expectStart()
            end
        end)
        local errorMessages = ""
        session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" }):Timeout(pParams.timeout)
        :ValidIf(function(_,data)
          local timeRAIResponse = timestamp()
          if pHmiOnReadyData.isReceived == false then
            actions.run.fail("RegisterAppInterface response was received before HMI on ready")
          else
            local timeBetweenHMIonReadyRAIResponse = timeRAIResponse - pHmiOnReadyData.time
            if timeBetweenHMIonReadyRAIResponse > pParams.timeRAIResponseAfterHMIonReady then
              actions.run.fail("RegisterAppInterface response was received with delay more than " ..
              pParams.timeRAIResponseAfterHMIonReady .. " msec after HMI on ready")
            end
          end
          for param, value in pairs (pParams.capabilitiesResponse) do
            if not utils.isTableEqual(data.payload[param], value) then
              errorMessages = errorMessages ..
                  errorMessage(param, data.payload[param], value)
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
  end)
end

local function initHmiOnReady(hmi_table)
  local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

  local exp_waiter = commonFunctions:createMultipleExpectationsWaiter(test, "HMI on ready")

  local hmi = actions.hmi.getConnection()

  local function ExpectRequest(name, hmi_table_element)
    if hmi_table_element.occurrence == 0 then
      hmi:ExpectRequest(name, hmi_table_element.params)
      :Times(0)
      return
    end
    local event = events.Event()
    event.level = 1
    event.matches = function(_, data)
      return data.method == name
    end

    local delay = hmi_table_element.delay or 0
    local occurrence = hmi_table_element.occurrence
    if occurrence == nil then
      occurrence = hmi_table_element.mandatory and 1 or AnyNumber()
    end
    local exp = hmi:ExpectEvent(event, name)
    :Times(occurrence)
    :Do(function(_, data)
        local function sendHMIResponse()
          hmi:SendResponse(data.id, data.method, "SUCCESS", hmi_table_element.params)
        end
        actions.run.runAfter(sendHMIResponse, delay)
      end)
    if hmi_table_element.mandatory then
      exp_waiter:AddExpectation(exp)
    end
    if hmi_table_element.pinned then
      exp:Pin()
    end
    return exp
  end

  local hmi_table_internal
  if type(hmi_table) == "table" then
    hmi_table_internal = utils.cloneTable(hmi_table)
  else
    hmi_table_internal = hmi_values.getDefaultHMITable()
  end

  local bc_update_app_list
  if hmi_table_internal.BasicCommunication then
    bc_update_app_list = hmi_table_internal.BasicCommunication.UpdateAppList
    hmi_table_internal.BasicCommunication.UpdateAppList = nil
    local bc_update_device_list = hmi_table_internal.BasicCommunication.UpdateDeviceList
    if SDL.buildOptions.webSocketServerSupport == "ON" and bc_update_device_list then
      bc_update_device_list.mandatory = true
      if not bc_update_device_list.occurrence then bc_update_device_list.occurrence = AtLeast(1) end
    end
  end

  local additionalExp = nil
  local additionalExpName = "BasicCommunication.UpdateDeviceList"
  for k_module, v_module in pairs(hmi_table_internal) do
    if type(v_module) ~= "table" then
      break
    end
    for k_request, v_request in pairs(v_module) do
      local request_name = k_module .. "." .. k_request
      local exp = ExpectRequest(request_name, v_request)
      if request_name == additionalExpName then
        additionalExp = exp
      end
    end
  end

  if type(bc_update_app_list) == "table" then
    ExpectRequest("BasicCommunication.UpdateAppList", bc_update_app_list)
    :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  end

  exp_waiter.expectation:Do(function()
    utils.cprint(35, "HMI is ready")
  end)

  hmi:SendNotification("BasicCommunication.OnReady")
  return exp_waiter.expectation, additionalExp
end

function m.connectMobileAndRegisterAppSuspend(pAppId, pCapResponse, pHMIParams, pDelayRaiResponse, pMobConnId, hasPTU)
  if not pCapResponse then pCapResponse = {} end
  if not pAppId then pAppId = 1 end
  if not pMobConnId then pMobConnId = 1 end

  local timeout = 15000
  local timeRAIResponseAfterHMIonReady = 2000

  local hmiOnReadyData = {
    isReceived = false,
    time = 0
  }

  local event = actions.run.createEvent()

  local function hmiOnReady()
    if not pDelayRaiResponse then pDelayRaiResponse = 0 end
    local exp, additionalExp = initHmiOnReady(pHMIParams)
    exp:Do(function()
        actions.run.wait(pDelayRaiResponse)
        :Do(function()
            hmiOnReadyData.time = timestamp()
            hmiOnReadyData.isReceived = true
          end)
      end)
      additionalExp:DoOnce(function()
        actions.init.connectMobile()
        :Do(function()
            actions.init.allowSDL()
            :Do(function()
                actions.hmi.getConnection():RaiseEvent(event, "Event")
              end)
          end)
      end)
  end

  local params = {
    appId = pAppId,
    mobConnId = pMobConnId,
    timeout = timeout,
    hasPTU = hasPTU,
    timeRAIResponseAfterHMIonReady = timeRAIResponseAfterHMIonReady,
    capabilitiesResponse = pCapResponse,
  }

  registerAppOnEvent(event, params, hmiOnReadyData)
  hmiOnReady()
end

function m.registerAppSuspend(pAppId, pCapResponse, pHMIParams, pDelayRaiResponse, pMobConnId, hasPTU)
  if not pCapResponse then pCapResponse = {} end
  if not pAppId then pAppId = 1 end
  if not pMobConnId then pMobConnId = 1 end

  local timeout = 15000
  local timeRunAfter = 3000
  local timeRAIResponseAfterHMIonReady = 3000

  local hmiOnReadyData = {
    isReceived = false,
    time = 0
  }

  local event = actions.run.createEvent()

  local function HMIonReady()
    if not pDelayRaiResponse then pDelayRaiResponse = 0 end
    actions.init.HMI_onReady(pHMIParams)
    :Do(function()
        actions.run.wait(pDelayRaiResponse)
        :Do(function()
            hmiOnReadyData.time = timestamp()
            hmiOnReadyData.isReceived = true
          end)
      end)
  end
  actions.run.runAfter(HMIonReady, timeRunAfter)

  local params = {
    appId = pAppId,
    mobConnId = pMobConnId,
    timeout = timeout,
    hasPTU = hasPTU,
    timeRAIResponseAfterHMIonReady = timeRAIResponseAfterHMIonReady,
    capabilitiesResponse = pCapResponse,
  }

  registerAppOnEvent(event, params, hmiOnReadyData)
  actions.hmi.getConnection():RaiseEvent(event, "Event")
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

  local timeout = 15000
  local timeRunAfter = 3000
  local timeRAIResponseAfterHMIonReady = 3000
  local timeHMIonReady
  local isHMIonReady = false
  local policyModes = {
    P  = "PROPRIETARY",
    EP = "EXTERNAL_PROPRIETARY",
    H  = "HTTP"
  }

  local function validateCapResponse(pData)
    local errorMessages = ""
    for param, value in pairs (pCapResponse) do
      if not utils.isTableEqual(pData.payload[param], value) then
        errorMessages = errorMessages ..
            errorMessage(param, pData.payload[param], value)
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
      local timeRAIResponse = timestamp()
      if isHMIonReady == false then
        actions.run.fail("RegisterAppInterface response was received before HMI on ready")
      else
        local timeBetweenHMIonReadyRAIResponse = timeRAIResponse - timeHMIonReady
        if timeBetweenHMIonReadyRAIResponse > timeRAIResponseAfterHMIonReady then
          actions.run.fail("RegisterAppInterface response was received with delay more than "
            .. timeRAIResponseAfterHMIonReady .. " msec after HMI on ready")
        end
      end
      return validateCapResponse(data)
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
        timeHMIonReady = timestamp()
        isHMIonReady = true
      end)
  end

  actions.run.runAfter(HMIonReady, timeRunAfter)

  local mobSession1 = actions.mobile.getSession(appSessionId1)
  local mobSession2 = actions.mobile.getSession(appSessionId2)
  local mobSession3 = actions.mobile.getSession(appSessionId3)

  local isAppRegisteredReceived = {
    [actions.app.getParams(appSessionId1).appName] = false,
    [actions.app.getParams(appSessionId2).appName] = false,
    [actions.app.getParams(appSessionId3).appName] = false
  }
  actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
  :ValidIf(function(_, data)
    local appName = data.params.application.appName
    if isAppRegisteredReceived[appName] == false then
      isAppRegisteredReceived[appName] = true
      return true
    elseif isAppRegisteredReceived[appName] == nil then
      return false, "SDL sends unexpected BasicCommunication.OnAppRegistered notification for app with name " .. appName
    else
      return false, "SDL sends BasicCommunication.OnAppRegistered notification twice for app with name" .. appName
    end
  end)
  :Do(function(_, data)
    local appName = data.params.application.appName
    local appID = data.params.application.appID
    if appName == actions.app.getParams(appSessionId1).appName then
      actions.app.setHMIId(appID, appSessionId1)
    elseif appName == actions.app.getParams(appSessionId2).appName then
      actions.app.setHMIId(appID, appSessionId2)
    elseif appName == actions.app.getParams(appSessionId3).appName then
      actions.app.setHMIId(appID, appSessionId3)
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
