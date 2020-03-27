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
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.getConfigAppParams = actions.getConfigAppParams
m.getAppsCount = actions.getAppsCount
m.init = actions.init
m.hmi = actions.hmi
m.run = actions.run
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.cloneTable = utils.cloneTable
m.isFileExist = utils.isFileExist
m.isTableContains = utils.isTableContains
m.isTableEqual = utils.isTableEqual
m.jsonFileToTable = utils.jsonFileToTable
m.print = utils.cprint
m.wait = utils.wait
m.getDefaultHMITable = hmi_values.getDefaultHMITable
m.start = actions.start
m.decode = json.decode
m.setSDLIniParameter = actions.sdl.setSDLIniParameter
m.getSDLIniParameter = actions.sdl.getSDLIniParameter
m.createSession = actions.mobile.createSession
m.getParams = actions.app.getParams
m.setHMIId = actions.app.setHMIId
m.isTableEqual = utils.isTableEqual
m.tableToString = utils.tableToString
m.getPreloadedPT = actions.sdl.getPreloadedPT
m.setPreloadedPT = actions.sdl.setPreloadedPT
m.null = actions.json.null

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


function m.getCacheCapabilityTable()
  local cacheFile = m.jsonFileToTable(hmiCapCacheFile)
  return cacheFile
end

function m.validation(actualData, expectedData, pMessage)
  if true ~= m.isTableEqual(actualData, expectedData) then
    return false, pMessage .. " contains unexpected parameters.\n" ..
    "Expected table: " .. m.tableToString(expectedData) .. "\n" ..
    "Actual table: " .. m.tableToString(actualData) .. "\n"
  end
  return true
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
    local storedCacheCapability = m.getCacheCapabilityTable()
    local hmiCapMap = {
      UI = {
        GetLanguage = { "language" },
        GetSupportedLanguages = { "languages" },
        GetCapabilities = { "displayCapabilities", "hmiCapabilities", "hmiZoneCapabilities",
        "softButtonCapabilities", "systemCapabilities"
          --,"audioPassThruCapabilities" - under clarification
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
      -- RC = {
      --   GetCapabilities = { "remoteControlCapability", "seatLocationCapability" }
      -- }
    }

    for mod, requests  in pairs(hmiCapMap) do
      for req, params in pairs(requests) do
        for _, pParam in ipairs(params) do
          if pParam == "language" or pParam == "hmiZoneCapabilities"  then
            if not (storedCacheCapability[mod][pParam] == expHmiCapabilities[mod][req].params[pParam]) then
             msg = msg .. mod .. "." .. pParam .. " contains unexpected value\n" ..
              " Expected: " .. tostring(expHmiCapabilities[mod][req].params[pParam]) .. "\n" ..
              " Actual: " .. tostring(storedCacheCapability[mod][pParam]) .. "\n"
            end
          else
            if not storedCacheCapability[mod][pParam] then
              msg = msg .. mod .. "." ..pParam.. " contains unexpected value\n" ..
                " Expected table:" .. m.tableToString(expHmiCapabilities[mod][req].params[pParam]) .. "\n" ..
                " Actual table: does not exist"  .. "\n"
            else
              if not m.isTableEqual(storedCacheCapability[mod][pParam], expHmiCapabilities[mod][req].params[pParam]) then
                msg = msg .. mod .. "." ..pParam.. " contains unexpected value\n" ..
                  " Expected table: " .. m.tableToString(expHmiCapabilities[mod][req].params[pParam]) .. "\n" ..
                  " Actual table: " .. m.tableToString(storedCacheCapability[mod][pParam]) .. "\n"
              end
            end
          end
        end
      end
    end
    if string.len(msg) > 0 then
      m.run.fail(msg)
    end
  else
    m.run.fail("HMICapabilitiesCacheFile file doesn't exist")
  end
end


function m.updateCacheFile(pModule, pGroup)
  local file = io.open(hmiCapCacheFile, "r")
  local json_data = file:read("*a")
  file:close()
  local capabilityData = m.decode(json_data)
  capabilityData[pModule][pGroup] = nil
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
    m.run.fail("HMICapabilitiesCacheFile file doesn't exist")
  end
end

function m.checkIfDoesNotExistCapabilityFile()
  if m.isFileExist(hmiCapCacheFile) then
    m.run.fail("HMICapabilitiesCacheFile file exists")
  end
end

function m.masterReset(pExpFunc)
  local isOnSDLCloseSent = false
  if pExpFunc then pExpFunc() end
  m.hmi.getConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "MASTER_RESET" })
  m.hmi.getConnection():ExpectNotification("BasicCommunication.OnSDLClose")
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
  m.hmi.getConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.hmi.getConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.hmi.getConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
    for i = 1, m.getAppsCount() do
      m.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end
  end)
  m.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(m.getAppsCount())
  local isSDLShutDownSuccessfully = false
  m.hmi.getConnection():ExpectNotification("BasicCommunication.OnSDLClose")
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

function m.registerApp(pAppId, pCapResponse, pMobConnId, hasPTU)

  if not pCapResponse then pCapResponse = {} end
  if not pAppId then pAppId = 1 end
  if not pMobConnId then pMobConnId = 1 end

  local policyModes = {
    P  = "PROPRIETARY",
    EP = "EXTERNAL_PROPRIETARY",
    H  = "HTTP"
  }
  local raiResponseData = pCapResponse
  raiResponseData.success = true
  raiResponseData.resultCode = "SUCCESS"

  local session = m.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
     -- local msg = ""
      local corId = session:SendRPC("RegisterAppInterface", m.getParams(pAppId))
      m.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = m.getParams(pAppId).appName } })
      :Do(function(_, d1)
          m.setHMIId(d1.params.application.appID, pAppId)
          if hasPTU then
            m.ptu.expectStart()
          end
        end)
      session:ExpectResponse(corId, raiResponseData )
      -- :ValidIf(function(_,data)
      --   for key, value in pairs (pCapResponse) do
      --     print(key)
      --     if not m.isTableEqual(data.payload[key], pCapResponse[key]) then
      --       msg = msg .. key.." contains unexpected parameters\n"..
      --         " Expected: " .. m.tableToString(pCapResponse[key]) .. "\n" ..
      --         " Actual: " .. m.tableToString(data.payload[key]) .. "\n"
      --     end
      --   end
      --   if string.len(msg) > 0 then
      --     return false, msg
      --   else
      --     return true
      --   end
      --end)
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

function m.updatePreloadedPT()
  local pt = m.getPreloadedPT()
  pt.policy_table.app_policies["default"].groups = { "Base-4", "REMOTE_CONTROL" }
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = m.null
  m.setPreloadedPT(pt)
end


return m
