---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local events = require('events')
local test = require("user_modules/dummy_connecttest")
local runner = require('user_modules/script_runner')
local json = require("modules/json")
local SDL = require('SDL')
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local m = {}
local hmiCapCacheFile = config.pathToSDL .. "storage/" .. "hmi_capabilities_cache.json"
--m.getSDLIniParameter("HMICapabilitiesCacheFile")

--[[ Shared Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.getHMICapabilitiesFromFile = actions.sdl.getHMICapabilitiesFromFile
m.setHMICapabilitiesToFile = actions.sdl.setHMICapabilitiesToFile
m.getMobileSession = actions.getMobileSession
m.getConfigAppParams = actions.getConfigAppParams
m.getAppsCount = actions.getAppsCount
m.getHMIConnection = actions.hmi.getConnection
m.failTestStep = actions.run.fail
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.start = actions.start
m.setSDLIniParameter = actions.sdl.setSDLIniParameter
m.getSDLIniParameter = actions.sdl.getSDLIniParameter
m.createSession = actions.mobile.createSession
m.getParams = actions.app.getParams
m.setHMIId = actions.app.setHMIId
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.tableToString = utils.tableToString
m.cloneTable = utils.cloneTable
m.isFileExist = utils.isFileExist
m.isTableContains = utils.isTableContains
m.isTableEqual = utils.isTableEqual
m.jsonFileToTable = utils.jsonFileToTable
m.print = utils.cprint
m.wait = utils.wait
m.null = actions.json.null
m.decode = json.decode
m.getDefaultHMITable = hmi_values.getDefaultHMITable

function m.noRequestsGetHMIParam()
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

function m.noResponseGetHMIParam()
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

function m.getCacheCapabilityTable(pHmiCapCacheFile)
  if not pHmiCapCacheFile then  pHmiCapCacheFile = hmiCapCacheFile end
  local cacheFile = m.jsonFileToTable(pHmiCapCacheFile)
  return cacheFile
end

function m.updatePreloadedPT()
  local pt = m.getPreloadedPT()
  pt.policy_table.app_policies["default"].groups = { "Base-4", "REMOTE_CONTROL" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = m.null
  m.setPreloadedPT(pt)
end

function m.checkContentCapabilityCacheFile(pExpHmiCapabilities)
  local expHmiCapabilities
  if not pExpHmiCapabilities then
    expHmiCapabilities = m.getDefaultHMITable()
  else
    expHmiCapabilities = pExpHmiCapabilities
  end
  if m.isFileExist(hmiCapCacheFile) then
    local msg = ""
    local  cacheTable = m.getCacheCapabilityTable()
    local hmiCapMap = {
      UI = {
        GetLanguage = { "language" },
        GetSupportedLanguages = { "languages" },
        GetCapabilities = { "displayCapabilities", "hmiCapabilities", "hmiZoneCapabilities",
        "softButtonCapabilities", "systemCapabilities" ,"audioPassThruCapabilitiesList"
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

    for mod, requests  in pairs(hmiCapMap) do
      for req, params in pairs(requests) do
        for _, pParam in ipairs(params) do
          if pParam == "language" or pParam == "hmiZoneCapabilities"  then
            if not (cacheTable[mod][pParam] == expHmiCapabilities[mod][req].params[pParam]) then
            msg = msg .. mod .. "." .. pParam .. " contains unexpected value\n" ..
              " Expected: " .. tostring(expHmiCapabilities[mod][req].params[pParam]) .. "\n" ..
              " Actual: " .. tostring(cacheTable[mod][pParam]) .. "\n"
            end
          else
            if pParam == "audioPassThruCapabilitiesList" then
              if not (cacheTable[mod].audioPassThruCapabilities == expHmiCapabilities[mod][req].params[pParam]) then
              msg = msg .. mod .. "." .. pParam .. " contains unexpected value\n" ..
                " Expected: " ..  m.tableToString(expHmiCapabilities[mod][req].params[pParam]) .. "\n" ..
                " Actual: " ..  m.tableToString(cacheTable[mod].audioPassThruCapabilities) .. "\n"
              end
            else
              if not cacheTable[mod][pParam] then
                msg = msg .. mod .. "." ..pParam.. " contains unexpected value\n" ..
                  " Expected table:" .. m.tableToString(expHmiCapabilities[mod][req].params[pParam]) .. "\n" ..
                  " Actual table: does not exist"  .. "\n"
              else
                if not m.isTableEqual(cacheTable[mod][pParam], expHmiCapabilities[mod][req].params[pParam]) then
                msg = msg .. mod .. "." ..pParam.. " contains unexpected value\n" ..
                  " Expected table: " .. m.tableToString(expHmiCapabilities[mod][req].params[pParam]) .. "\n" ..
                  " Actual table: " .. m.tableToString(cacheTable[mod][pParam]) .. "\n"
                end
              end
            end
          end
        end
      end
    end
    if string.len(msg) > 0 then
      m.failTestStep(msg)
    end
  else
    m.failTestStep("HMICapabilitiesCacheFile file doesn't exist")
  end
end

function m.updateHMISystemInfo(pVersion)
  local hmiValues = m.getDefaultHMITable()
  hmiValues.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = "New_ccpu_"..pVersion,
      language = "EN-US",
      wersCountryCode = "wersCountryCode"
    }
  }
  return hmiValues
end

function m.updateCacheFile(pModule, pGroup)
  local file = io.open(hmiCapCacheFile, "r")
  local json_data = file:read("*a")
  file:close()
  local capabilityData = m.decode(json_data)
  capabilityData[pModule][pGroup] = nil
end

function m.updatedHMICapTab()
  local hmiCapTbl = m.getHMICapabilitiesFromFile()
    table.remove(hmiCapTbl.UI.displayCapabilities.textFields, 1)
    hmiCapTbl.UI.hmiZoneCapabilitie = "BACK"
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

function m.updateHMICapabilities()
  local hmiCapTbl = m.updatedHMICapTab()
  m.setHMICapabilitiesToFile(hmiCapTbl)
end

function m.deleteHMICapabilitiesCacheFile()
  os.remove(hmiCapCacheFile)
  m.checkIfDoesNotExistCapabilityFile()
end

function m.checkIfExistCapabilityFile(pFileName)
  if not pFileName then pFileName = "hmi_capabilities_cache.json" end
  if m.isFileExist(config.pathToSDL .. "storage/" .. pFileName) then
    m.print(35, pFileName .. " file was created")
  else
    m.failTestStep("HMICapabilitiesCacheFile file doesn't exist")
  end
end

function m.checkIfDoesNotExistCapabilityFile()
  if m.isFileExist(hmiCapCacheFile) then
    m.failTestStep("HMICapabilitiesCacheFile file exists")
  end
end

function  m.getSystemCapability(pSystemCapabilityType, pResponseCapabilities)
  local msg = ""
  local mobSession = m.getMobileSession()
  local cid = mobSession:SendRPC("GetSystemCapability", { systemCapabilityType = pSystemCapabilityType })
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf(function(_,data)
    for key, value in pairs (pResponseCapabilities) do
      if not data.payload.systemCapability[key] then
        msg = key .. " contains unexpected value\n" ..
          " Expected table:" .. m.tableToString(pResponseCapabilities[key]) .. "\n" ..
          " Actual table: does not exist"  .. "\n"
      else
        if not m.isTableEqual(data.payload.systemCapability[key], pResponseCapabilities[key]) then
          msg = msg .. key.." contains unexpected parameters\n"..
            " Expected: " .. m.tableToString(pResponseCapabilities[key]) .. "\n" ..
            " Actual: " .. m.tableToString(data.payload.systemCapability[key]) .. "\n"
        end
      end
    end
    if string.len(msg) > 0 then
      return false, msg
    else
      return true
    end
  end)
end

function m.onLanguageChange(pLanguage)
  m.getHMIConnection():SendNotification("TTS.OnLanguageChange", { language = pLanguage })
  m.getHMIConnection():SendNotification("VR.OnLanguageChange", { language = pLanguage })
  m.getHMIConnection():SendNotification("UI.OnLanguageChange", { language = pLanguage })
end

function m.checkLanguageCapability(pLanguage)
  local data = m.getCacheCapabilityTable()
  if data.VR.language == pLanguage and data.TTS.language == pLanguage and data.UI.language == pLanguage then
    m.print(35, "Languages were changed")
  else
    m.failTestStep("SDL doesn't updated cache file")
  end
end

function m.updateHMILanguage(pLanguage)
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

  local session = m.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
     local msg = ""
      local corId = session:SendRPC("RegisterAppInterface", m.getParams(pAppId))
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = m.getParams(pAppId).appName } })
      :Do(function(_, d1)
          m.setHMIId(d1.params.application.appID, pAppId)
          if hasPTU then
            m.ptu.expectStart()
          end
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" }  )
      :ValidIf(function(_,data)
        for key, value in pairs (pCapResponse) do
          print(key)
          if not m.isTableEqual(data.payload[key], pCapResponse[key]) then
            msg = msg .. key.." contains unexpected parameters\n"..
              " Expected: " .. m.tableToString(pCapResponse[key]) .. "\n" ..
              " Actual: " .. m.tableToString(data.payload[key]) .. "\n"
          end
        end
        if string.len(msg) > 0 then
          return false, msg
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
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "MASTER_RESET" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
    isOnSDLCloseSent = true
    SDL.DeleteFile()
  end)
  :Times(AtMost(1))
  m.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then utils.cprint(35, "BC.OnSDLClose was not sent") end
    if SDL:CheckStatusSDL() == SDL.RUNNING then SDL:StopSDL() end
  end)
end

function m.ignitionOff()
  config.ExitOnCrash = false
  local timeout = 5000
  local function removeSessions()
    for i = 1, m.getAppsCount() do
      test.mobileSession[i] = nil
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "SDL shutdown")
  :Do(function()
    removeSessions()
    StopSDL()
    config.ExitOnCrash = true
  end)
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
    for i = 1, m.getAppsCount() do
      m.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end
  end)
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(m.getAppsCount())
  local isSDLShutDownSuccessfully = false
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
    m.print(35, "SDL was shutdown successfully")
    isSDLShutDownSuccessfully = true
    RAISE_EVENT(event, event)
  end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      m.print(35, "SDL was shutdown forcibly")
      RAISE_EVENT(event, event)
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

return m
