---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local events = require('events')
local test = require("user_modules/dummy_connecttest")
local runner = require('user_modules/script_runner')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require("modules/json")
local SDL = require('SDL')
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local m = {}
local HMICacheFile_pathToFile = config.pathToSDL .. "storage/"

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

function m.getCacheCapabilityTable()
  local cacheFile = m.jsonFileToTable(HMICacheFile_pathToFile .. "hmi_capabilities_cache.json")
  return cacheFile
end

function m.checkContentCapabilityCacheFile()
  if m.isFileExist(HMICacheFile_pathToFile .. "hmi_capabilities_cache.json") then
    local cap = { 
      UI = { "audioPassThruCapabilities", "displayCapabilities" , "hmiCapabilities", "hmiZoneCapabilities", "language",
        "languages", "softButtonCapabilities", "systemCapabilities"},
      VR = { "language", "languages", "vrCapabilities" },
      TTS = { "language", "languages", "prerecordedSpeechCapabilities", "speechCapabilities" },
      Buttons = { "capabilities", "presetBankCapabilities" },
      VehicleInfo = { "vehicleType" },
      RC = { "remoteControlCapability", "seatLocationCapability" }
    }    
    local storedCacheCapability = m.getCacheCapabilityTable()
    for mod, req  in pairs(cap) do
      for _, pReq  in ipairs(req) do
        if storedCacheCapability[mod][pReq] == nil then
          m.run.fail(mod .. pReq .. " Capability doesn't exist")
        end 
      end
    end
  else
    m.run.fail("HMICapabilitiesCacheFile file doesn't exist")
  end
end

function m.backUpIniFileAndSetHBValue(pParams)
  commonPreconditions:BackupFile("smartDeviceLink.ini")
  commonFunctions:write_parameter_to_smart_device_link_ini("HMICapabilitiesCacheFile", pParams)
end

function m.restoreIniFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function m.updateCacheFile(pModule, pGroup)
  local file = io.open(HMICacheFile_pathToFile.. "hmi_capabilities_cache.json", "r")
  local json_data = file:read("*a")
  file:close()
  local capabilityData = m.decode(json_data)
  capabilityData[pModule][pGroup] = nil
end

function m.precondition()
  if m.isFileExist(HMICacheFile_pathToFile .. "hmi_capabilities_cache.json") then
    m.deleteHMICapabilitiesCacheFile()
  end
  m.preconditions()
end

function m.deleteHMICapabilitiesCacheFile()
  os.remove(HMICacheFile_pathToFile .. "hmi_capabilities_cache.json")
  m.checkIfDoesNotExistCapabilityFile()
end

function m.checkIfExistCapabilityFile()
  if m.isFileExist(HMICacheFile_pathToFile .. "hmi_capabilities_cache.json") then
    m.print(35, "HMICapabilitiesCacheFile was created")
  else
    m.run.fail("HMICapabilitiesCacheFile file doesn't exist")
  end
end

function m.checkIfDoesNotExistCapabilityFile()
  if m.isFileExist(HMICacheFile_pathToFile .. "hmi_capabilities_cache.json") then
    m.run.fail("HMICapabilitiesCacheFile file does exist")
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

return m
