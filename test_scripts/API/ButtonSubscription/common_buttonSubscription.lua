---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local events = require('events')

--[[ Variables ]]
local m = actions
m.hashId = {}
m.wait = utils.wait
m.cloneTable = utils.cloneTable

m.buttons = {
  "OK",
  "PLAY_PAUSE",
  "SEEKLEFT",
  "SEEKRIGHT",
  "TUNEUP",
  "TUNEDOWN",
  "PRESET_0",
  "PRESET_1",
  "PRESET_2",
  "PRESET_3",
  "PRESET_4",
  "PRESET_5",
  "PRESET_6",
  "PRESET_7",
  "PRESET_8",
  "PRESET_9",
  "SEARCH"
}
m.media_buttons = {
  "PLAY_PAUSE",
  "SEEKLEFT",
  "SEEKRIGHT",
  "TUNEUP",
  "TUNEDOWN",
  "PRESET_0",
  "PRESET_1",
  "PRESET_2",
  "PRESET_3",
  "PRESET_4",
  "PRESET_5",
  "PRESET_6",
  "PRESET_7",
  "PRESET_8",
  "PRESET_9"
}

m.errorCode = {
  "UNSUPPORTED_REQUEST",
  "DISALLOWED",
  "REJECTED",
  "IN_USE",
  "DATA_NOT_AVAILABLE",
  "TIMED_OUT",
  "INVALID_DATA",
  "CHAR_LIMIT_EXCEEDED",
  "INVALID_ID",
  "DUPLICATE_NAME",
  "APPLICATION_NOT_REGISTERED",
  "OUT_OF_MEMORY",
  "TOO_MANY_PENDING_REQUESTS",
  "GENERIC_ERROR",
  "USER_DISALLOWED",
  "TRUNCATED_DATA",
  "READ_ONLY"
}

--[[ Common Functions ]]
--[[ @rpcSuccess: performs button Subscription and Unsubscription with SUCCESS resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pRpc - RPC name
--! pButtonName - button name
--! @return: none
--]]
function m.rpcSuccess(pAppId, pRpc, pButtonName)
  local cid = m.getMobileSession(pAppId):SendRPC(pRpc, { buttonName = pButtonName })
  EXPECT_HMICALL("Buttons." .. pRpc,{ appID = m.getHMIAppId(pAppId), buttonName = pButtonName })
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
  end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    m.hashId[pAppId] = data.payload.hashID
  end)
end

--[[ @rpcUnsuccess: performs button Subscription and Unsubscription with ERROR resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pRpc - RPC name
--! pButtonName - button name
--! pResultCode - result error
--! @return: none
--]]
function m.rpcUnsuccess(pAppId, pRpc, pButtonName, pResultCode)
  local cid = m.getMobileSession(pAppId):SendRPC(pRpc, { buttonName = pButtonName })
  EXPECT_HMICALL("Buttons." .. pRpc,{ appID = m.getHMIAppId(pAppId), buttonName = pButtonName })
  :Times(0)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = pResultCode })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ @buttonPress: performs press button
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pButtonName - button name
--! pCustomButtonID - custom button ID
--! @return: none
--]]
function m.buttonPress(pAppId, pButtonName, pCustomButtonID)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONDOWN", appID = m.getHMIAppId(pAppId), customButtonID = pCustomButtonID })
  m.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = pButtonName, mode = "SHORT", appID = m.getHMIAppId(pAppId), customButtonID = pCustomButtonID })
  m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONUP", appID = m.getHMIAppId(pAppId), customButtonID = pCustomButtonID })
  m.getMobileSession(pAppId):ExpectNotification( "OnButtonEvent",
    { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN", customButtonID = pCustomButtonID },
    { buttonName = pButtonName, buttonEventMode = "BUTTONUP",  customButtonID = pCustomButtonID })
  :Times(2)
  m.getMobileSession(pAppId):ExpectNotification( "OnButtonPress",
    { buttonName = pButtonName, buttonPressMode = "SHORT",  customButtonID = pCustomButtonID })
end

--[[ @buttonPressUnsuccess: performs unsuccessful press button
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pButtonName - button name
--! pCustomButtonID - custom button ID
--! @return: none
--]]
function m.buttonPressUnsuccess(pAppId, pButtonName, pCustomButtonID)
  if not pAppId then pAppId = 1 end
    m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
      { name = pButtonName, mode = "BUTTONDOWN", appID = m.getHMIAppId(pAppId), customButtonID = pCustomButtonID })
    m.getHMIConnection():SendNotification("Buttons.OnButtonPress",
      { name = pButtonName, mode = "SHORT", appID = m.getHMIAppId(pAppId), customButtonID = pCustomButtonID })
    m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
      { name = pButtonName, mode = "BUTTONUP", appID = m.getHMIAppId(pAppId), customButtonID = pCustomButtonID })
    m.getMobileSession(pAppId):ExpectNotification( "OnButtonEvent")
    :Times(0)
    m.getMobileSession(pAppId):ExpectNotification("OnButtonPress")
    :Times(0)
end

--[[ @rpcHMIwithoutResponse: performs case when HMI did not respond
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pRpc - RPC name
--! pButtonName - button name
--! pErrorCode - result error
--! @return: none
--]]
function m.rpcHMIwithoutResponse(pAppId, pRpc, pButtonName, pErrorCode)
  local cid = m.getMobileSession(pAppId):SendRPC(pRpc, { buttonName = pButtonName })
  EXPECT_HMICALL("Buttons." .. pRpc,{ appID = m.getHMIAppId(pAppId), buttonName = pButtonName })
  :Do(function()
    -- HMI did not response
  end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = pErrorCode })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ @rpcHMIResponseErrorCode: performs case when HMI respond with error code
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pRpc - RPC name
--! pButtonName - button name
--! pErrorCode - result error
--! @return: none
--]]
function m.rpcHMIResponseErrorCode(pAppId, pRpc, pButtonName, pErrorCode)
  local cid = m.getMobileSession(pAppId):SendRPC(pRpc, { buttonName = pButtonName })
  EXPECT_HMICALL("Buttons." .. pRpc,{ appID = m.getHMIAppId(pAppId), buttonName = pButtonName })
  :Do(function(_, data)
    m.getHMIConnection():SendError(data.id, data.method, pErrorCode, "Error code")
  end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = pErrorCode })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ @unexpectedDisconnect: closing connection
--! @parameters: none
--! @return: none
--]]
function m.unexpectedDisconnect()
  test.mobileConnection:Close()
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Do(function()
    for i = 1, m.getAppsCount() do
      test.mobileSession[i] = nil
    end
  end)
end

--[[ @connectMobile: create connection
--! @parameters: none
--! @return: none
--]]
function m.connectMobile()
  test.mobileConnection:Connect()
  EXPECT_EVENT(events.connectedEvent, "Connected")
  :Do(function()
    utils.cprint(35, "Mobile connected")
  end)
end

--[[ @reRegisterAppSuccess: re-register application with SUCCESS resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pCheckResumptionData - verification function for resumption data
--! pCheckResumptionHMILevel - verification function for resumption HMI level
--! @return: none
--]]
function m.reRegisterAppSuccess(pAppId, pCheckResumptionData, pCheckResumptionHMILevel)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
    local params = m.cloneTable(m.getConfigAppParams(pAppId))
    params.hashID = m.hashId[pAppId]
    local corId = mobSession:SendRPC("RegisterAppInterface", params)
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
      application = { appName = m.getConfigAppParams(pAppId).appName }
    })
    mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      mobSession:ExpectNotification("OnPermissionsChange")
    end)
  end)
  pCheckResumptionData(pAppId)
  pCheckResumptionHMILevel(pAppId)
end

--[[ @resumptionFullHMILevel: checks resumption to full HMI level
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
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

--[[ @ignitionOff: perform ignition off
--! @parameters: none
--! @return: none
--]]
function m.ignitionOff()
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
    m.wait(1000)
  end)
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
    for i = 1, m.getAppsCount() do
      m.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end
  end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(m.getAppsCount())
  local isSDLShutDownSuccessfully = false
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
    utils.cprint(35, "SDL was shutdown successfully")
    isSDLShutDownSuccessfully = true
    RAISE_EVENT(event, event)
  end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      RAISE_EVENT(event, event)
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

--[[ @reRegisterApp: re-register application with RESUME_FAILED resultCode
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! pCheckResumptionData - verification function for resumption data
--! pCheckResumptionHMILevel - verification function for resumption HMI level
--! pErrorResponseRpc - RPC name for error response
--! pRAIResponseExp - time for expectation of RAI response
--! @return: none
--]]
function m.reRegisterApp(pAppId, pCheckResumptionData, pCheckResumptionHMILevel, pErrorResponseRpc, pRAIResponseExp)
  if not pAppId then pAppId = 1 end
  if not pRAIResponseExp then pRAIResponseExp = 10000 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
    local params = m.cloneTable(m.getConfigAppParams(pAppId))
    params.hashID = m.hashId[pAppId]
    local corId = mobSession:SendRPC("RegisterAppInterface", params)
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
      application = { appName = m.getConfigAppParams(pAppId).appName }
    })
    mobSession:ExpectResponse(corId, { success = true, resultCode = pErrorResponseRpc })
    :Do(function()
      pCheckResumptionHMILevel(pAppId)
      mobSession:ExpectNotification("OnPermissionsChange")
    end)
    :Timeout(pRAIResponseExp)
  end)
  pCheckResumptionData(pAppId)
end

return m
