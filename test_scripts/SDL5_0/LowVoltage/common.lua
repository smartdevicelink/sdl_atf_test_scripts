---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local events = require('events')
local test = require('user_modules/dummy_connecttest')
local expectations = require('expectations')
local Expectation = expectations.Expectation
local SDL = require('SDL')
local utils = require("user_modules/utils")
local actions = require("user_modules/sequences/actions")

--[[ Module ]]
local m = actions

m.cprint = utils.cprint
m.wait = utils.wait
m.SDL = SDL

--[[ Constants ]]
m.appParams = {
  [1] = { appHMIType = "DEFAULT", isMediaApplication = false },
  [2] = { appHMIType = "MEDIA", isMediaApplication = true },
  [3] = { appHMIType = "DEFAULT", isMediaApplication = false },
  [4] = { appHMIType = "DEFAULT", isMediaApplication = false }
}

m.rpcSend = {}
m.rpcCheck = {}

m.signal = {
  LOW_VOLTAGE = 35,
  WAKE_UP = 36,
  IGNITION_OFF = 37
}

for i = 1, 4 do
  config["application" .. i].registerAppInterfaceParams.appHMIType = { m.appParams[i].appHMIType }
  config["application" .. i].registerAppInterfaceParams.isMediaApplication = m.appParams[i].isMediaApplication
end

--[[ Variables ]]
local grammarId = {}
local hashId = {}
local origGetMobileSession = actions.getMobileSession

-- Override functions of Actions module

--[[ @registerStartSecureServiceFunc: register function to expect Any event on mobile connection
--! @parameters:
--! pMobSession - mobile session
--]]
local function registerCustomExpFunctions(pMobSession)
  --[[ @ExpectAny: register expectation for any event on Mobile connection
  --! @parameters: none
  --]]
  function pMobSession:ExpectAny()
    local session = self.mobile_session_impl
    local event = events.Event()
    event.matches = function(_, data)
      return data.sessionId == session.sessionId.get()
    end
    local ret = Expectation("Any Mobile Event", session.connection)
    ret.event = event
    event_dispatcher:AddEvent(session.connection, event, ret)
    test:AddExpectation(ret)
    return ret
  end
end

function m.getMobileSession(pAppId)
  if not pAppId then pAppId = 1 end
  if not test.mobileSession[pAppId] then
    local session = origGetMobileSession(pAppId)
    registerCustomExpFunctions(session)
  end
  return origGetMobileSession(pAppId)
end

function m.activateApp(pAppId)
  if not pAppId then pAppId = 1 end
  local requestId = test.hmiConnection:SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  test.hmiConnection:ExpectResponse(requestId)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", systemContext = "MAIN" })
  utils.wait()
end

--[[ Functions ]]
--[[ @execCMD: execute any linux command and return result
--! @parameters:
--! pCmd - command to execute
--! @return: result
--]]
local function execCMD(pCmd)
  local handle = io.popen(pCmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

--[[ @ExpectAny: register expectation for any event on HMI connection
--! @parameters: none
--]]
function test.hmiConnection:ExpectAny()
  local event = events.Event()
  event.matches = function() return true end
  local ret = Expectation("Any HMI Event", self)
  ret.event = event
  event_dispatcher:AddEvent(self, event, ret)
  test:AddExpectation(ret)
  return ret
end

--[[ @cleanSessions: delete all mobile sessions and close mobile connection
--! @parameters: none
--! @return: none
--]]
function m.cleanSessions()
  for i = 1, m.getAppsCount() do
    test.mobileSession[i] = nil
    utils.cprint(35, "Mobile session " .. i .. " deleted")
  end
  test.mobileConnection:Close()
  utils.wait()
end

--[[ @unexpectedDisconnect: perform unexpected disconnect sequence
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.unexpectedDisconnect(pAppId)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", {
    unexpectedDisconnect = true,
    appID = m.getHMIAppId(pAppId)
  })
  m.getMobileSession(pAppId):Stop()
  utils.wait(1000)
end

--[[ @unregisterApp: unregister application sequence
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.unregisterApp(pAppId)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("UnregisterAppInterface", {})
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", {
    unexpectedDisconnect = false,
    appID = m.getHMIAppId(pAppId)
  })
end

--[[ @sendSignal: send signal
--! @parameters:
--! pSignal - signal
--! @return: none
--]]
function m.sendSignal(pSignal)
  local cmd = "ps -ef | grep smartDeviceLinkCore | grep -v grep | awk '{print $2}' | xargs kill -" .. m.signal[pSignal]
  utils.cprint(35, "Sending signal '" .. pSignal .. "'")
  execCMD(cmd)
end

--[[ @connectMobile: connect mobile device
--! @parameters: none
--! @return: none
--]]
function m.connectMobile()
  EXPECT_EVENT(events.connectedEvent, "Connected")
  :Do(function()
      utils.cprint(35, "Mobile connected")
    end)
  test.mobileConnection:Connect()
end

--[[ @reRegisterApp: re-register application
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pCheckAppId - verification function for HMI Application id
--! pCheckResumptionData - verification function for resumption data
--! pCheckResumptionHMILevel - verification function for resumption HMI level
--! pResultCode - expected result code
--! pDelay - delay
--! @return: none
--]]
function m.reRegisterApp(pAppId, pCheckAppId, pCheckResumptionData, pCheckResumptionHMILevel, pResultCode, pDelay)
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = config["application" .. pAppId].registerAppInterfaceParams
      params.hashID = hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
        application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName }
      })
      :ValidIf(function(_, data)
          return pCheckAppId(pAppId, data)
        end)
      mobSession:ExpectResponse(corId, { success = true, resultCode = pResultCode })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
  pCheckResumptionData(pAppId)
  pCheckResumptionHMILevel(pAppId)
  utils.wait(pDelay)
end

--[[ @waitUntilSocketIsClosed: wait some time until SDL logger is closed
--! @parameters: none
--! @return: none
--]]
local function waitUntilSDLLoggerIsClosed()
  utils.cprint(35, "Wait until SDL Logger is closed ...")
  local function getNetStat()
    local cmd = "netstat"
      .. " | grep -E '" .. config.sdl_logs_host .. ":" .. config.sdl_logs_port .. "\\s*FIN_WAIT'"
      .. " | wc -l"
    return tonumber(execCMD(cmd))
  end
  while getNetStat() > 0 do
    os.execute("sleep 1")
  end
  os.execute("sleep 1")
end

--[[ @sendLowVoltageSignal: send 'SDL_LOW_VOLTAGE' signal
--! @parameters: none
--! @return: none
--]]
function m.sendLowVoltageSignal()
  m.sendSignal("LOW_VOLTAGE")
  m.wait()
end

--[[ @failTestCase: fail test case
--! @parameters:
--! pCause - message with reason of the fail
--! @return: none
--]]
function m.failTestCase(pCause)
  test:FailTestCase(pCause)
end

--[[ @sendIgnitionOffSignal: send 'IGNITION_OFF' signal
--! @parameters: none
--! @return: none
--]]
function m.sendIgnitionOffSignal()
  local isSDLStoppedByItself = true
  m.sendSignal("IGNITION_OFF")
  os.execute("sleep 1")
  local count = 0
  while SDL:CheckStatusSDL() == SDL.RUNNING do
    count = count + 1
    if count == 10 then
      SDL:StopSDL()
      waitUntilSDLLoggerIsClosed()
      isSDLStoppedByItself = false
    end
    os.execute("sleep 1")
  end
  if not isSDLStoppedByItself then
    m.failTestCase("SDL was not stopped")
  end
end

--[[ @sendWakeUpSignal: send 'WAKE_UP' signal
--! @parameters: none
--! @return: none
--]]
function m.sendWakeUpSignal()
  m.sendSignal("WAKE_UP")
  utils.wait()
end

--[[ @waitUntilResumptionDataIsStored: wait some time until SDL saves resumption data
--! @parameters: none
--! @return: none
--]]
function m.waitUntilResumptionDataIsStored()
  utils.cprint(35, "Wait ...")
  local timeoutToSafe = commonFunctions:read_parameter_from_smart_device_link_ini("AppSavePersistentDataTimeout")
  local fileName = commonPreconditions:GetPathToSDL()
    .. commonFunctions:read_parameter_from_smart_device_link_ini("AppInfoStorage")
  local function isFileExist()
    local f = io.open(fileName, "r")
    if f ~= nil then
      io.close(f)
      m.wait(timeoutToSafe + 1000)
      return true
    else
      return false
    end
  end
  while not isFileExist() do
    os.execute("sleep 1")
  end
end

m.rpcSend.AddCommand = function(pAppId, pCommandId)
    if not pCommandId then pCommandId = 1 end
    local cmd = "CMD" .. pCommandId
    local cid = m.getMobileSession(pAppId):SendRPC("AddCommand", { cmdID = pCommandId, vrCommands = { cmd }})
    m.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        grammarId[pAppId] = data.params.grammarID
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
    :Do(function(_, data)
        hashId[pAppId] = data.payload.hashID
      end)
  end
m.rpcSend.AddSubMenu = function(pAppId)
    local cid = m.getMobileSession(pAppId):SendRPC("AddSubMenu", { menuID = 1, position = 500, menuName = "SubMenu" })
    m.getHMIConnection():ExpectRequest("UI.AddSubMenu")
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
    :Do(function(_, data)
        hashId[pAppId] = data.payload.hashID
      end)
  end
m.rpcSend.CreateInteractionChoiceSet = function(pAppId)
    local cid = m.getMobileSession(pAppId):SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = 1,
      choiceSet = {
        { choiceID = 1, menuName = "Choice", vrCommands = { "VrChoice" }}
      }
    })
    m.getHMIConnection():ExpectRequest("VR.AddCommand")
    :Do(function(_, data)
        grammarId[pAppId] = data.params.grammarID
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
    :Do(function(_, data)
        hashId[pAppId] = data.payload.hashID
      end)
  end
m.rpcSend.NoRPC = function() end

m.rpcCheck.AddCommand = function(pAppId, pCommandId)
    if not pCommandId then pCommandId = 1 end
    local cmd = "CMD" .. pCommandId
    m.getHMIConnection():ExpectRequest("VR.AddCommand", {
      cmdID = pCommandId,
      vrCommands = { cmd },
      type = "Command",
      grammarID = grammarId[pAppId],
      appID = m.getHMIAppId(pAppId)
    })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
  end
m.rpcCheck.AddSubMenu = function(pAppId)
    m.getHMIConnection():ExpectRequest("UI.AddSubMenu", {
      menuID = 1,
      menuParams = {
        position = 500,
        menuName = "SubMenu"
      },
      appID = m.getHMIAppId(pAppId)
    })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
  end
m.rpcCheck.CreateInteractionChoiceSet = function(pAppId)
  m.getHMIConnection():ExpectRequest("VR.AddCommand", {
      cmdID = 1,
      vrCommands = { "VrChoice" },
      type = "Choice",
      grammarID = grammarId[pAppId],
      appID = m.getHMIAppId(pAppId)
    })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
  end
m.rpcCheck.NoRPC = function() end

--[[ @configureHMILevels: configures app's HMI levels:
--! 1 - FULL
--! 2 - LIMITED
--! 3 - BACKGROUND
--! 4 - NONE
--! @parameters:
--! pNumOfApps - number of applications
--! @return: none
--]]
function m.configureHMILevels(pNumOfApps)
  local apps = {
    [1] = { 1 },
    [2] = { 2, 1 },
    [3] = { 2, 3, 1 },
    [4] = { 2, 3, 1 }
  }
  for k, i in pairs(apps[pNumOfApps]) do
    local function activateApp()
      local cid = m.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId(i) })
      m.getHMIConnection():ExpectResponse(cid)
      :Do(function() utils.cprint(35, "Activate App: " .. i) end)
    end
    RUN_AFTER(activateApp, 100 * k)
  end
  m.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })

  if pNumOfApps >= 2 then
    m.getMobileSession(2):ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE" },
      { hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
    :Times(2)
  end
  if pNumOfApps >= 3 then
    m.getMobileSession(3):ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
      { hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
    :Times(2)
  end
end

--[[ @checkResumptionHMILevel: verifies app's HMI levels while resumption
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.checkResumptionHMILevel(pAppId)
  local f = {}
  f[1] = function()
    m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(1) })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
      end)
    m.getMobileSession(1):ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
      { hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
    :Times(2)
  end
  f[2] = function()
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnResumeAudioSource", {
      appID = m.getHMIAppId(2) })
    m.getMobileSession(2):ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
      { hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE" })
    :Times(2)
  end
  f[3] = function()
    m.getMobileSession(3):ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    :Times(1)
  end
  f[4] = function()
    m.getMobileSession(4):ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    :Times(1)
  end
  f[pAppId]()
end

--[[ @deactivateAppToLimited: bring app to LIMITED HMI level
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.deactivateAppToLimited(pAppId)
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {appID = m.getHMIAppId(pAppId)})
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
end

return m
