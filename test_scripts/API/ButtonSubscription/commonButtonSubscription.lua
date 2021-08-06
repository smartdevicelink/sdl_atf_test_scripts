---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local SDL = require("SDL")
local hmi_values = require('user_modules/hmi_values')
local color = require("user_modules/consts").color

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
runner.testSettings.isSelfIncluded = false

--[[ Module ]]
local m = {}

--[[ Common Proxy Functions ]]
m.runner = runner
m.start = actions.start
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.connectMobile = actions.mobile.connect
m.activateApp = actions.app.activate
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.hmi.getConnection
m.getHMIAppId = actions.getHMIAppId
m.registerApp = actions.app.register
m.registerAppWOPTU = actions.app.registerNoPTU
m.getAppsCount = actions.getAppsCount
m.getConfigAppParams = actions.getConfigAppParams
m.policyTableUpdate = actions.policyTableUpdate
m.getHMICapabilitiesFromFile = actions.sdl.getHMICapabilitiesFromFile
m.setHMICapabilitiesToFile = actions.sdl.setHMICapabilitiesToFile
m.getDefaultHMITable = hmi_values.getDefaultHMITable
m.hashId = {}
m.wait = utils.wait
m.cloneTable = utils.cloneTable
m.spairs = utils.spairs
m.createEvent = actions.run.createEvent

--[[ Common Constants and Variables ]]
m.isExpected = 1
m.isNotExpected = 0
m.customButtonID = 1

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
  "SEARCH",
  "NAV_CENTER_LOCATION",
  "NAV_ZOOM_IN",
  "NAV_ZOOM_OUT",
  "NAV_PAN_UP",
  "NAV_PAN_UP_RIGHT",
  "NAV_PAN_RIGHT",
  "NAV_PAN_DOWN_RIGHT",
  "NAV_PAN_DOWN",
  "NAV_PAN_DOWN_LEFT",
  "NAV_PAN_LEFT",
  "NAV_PAN_UP_LEFT",
  "NAV_TILT_TOGGLE",
  "NAV_ROTATE_CLOCKWISE",
  "NAV_ROTATE_COUNTERCLOCKWISE",
  "NAV_HEADING_TOGGLE"
}

m.mediaButtons = {
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
  "ABORTED",
  "IN_USE",
  "IGNORED",
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
  "READ_ONLY"
}

m.customButtonCapabilities = {
  name = "CUSTOM_BUTTON",
  shortPressAvailable = true,
  longPressAvailable = true,
  upDownAvailable = true
}

--[[ Common Functions ]]
--[[ @startCacheUsed: starting sequence: starting of SDL, initialization of HMI
--! @pHMIParams - parameters with HMI capabilities
--! @isCacheUsed - true if it's expected SDL will use HMI capabilities cache, otherwise false
--! @return: Start event expectation
--]]
function m.startCacheUsed(pHMIParams, isCacheUsed)
  local event = actions.run.createEvent()
  actions.init.SDL()
  :Do(function()
      actions.init.HMI()
      :Do(function()
          utils.cprint(35, "HMI initialized")
          test:initHMI_onReady(pHMIParams, isCacheUsed)
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
    end)
  return actions.hmi.getConnection():ExpectEvent(event, "Start event")
end

--[[ @rpcSuccess: performs button Subscription and Unsubscription with SUCCESS resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pRpc - RPC name
--! pButtonName - button name
--! @return: none
--]]
function m.rpcSuccess(pAppId, pRpc, pButtonName)
  local cid = m.getMobileSession(pAppId):SendRPC(pRpc, { buttonName = pButtonName })
  m.getHMIConnection():ExpectRequest("Buttons." .. pRpc,{ appID = m.getHMIAppId(pAppId), buttonName = pButtonName })
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
  m.getHMIConnection():ExpectRequest("Buttons." .. pRpc,{ appID = m.getHMIAppId(pAppId), buttonName = pButtonName })
  :Times(0)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = pResultCode })
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ @buttonPress: performs press button
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pButtonName - button name
--! pExpTimesApp: number of notifications for 1st app
--! pCustomButtonID - custom button ID
--! @return: none
--]]
function m.buttonPress(pAppId, pButtonName, pExpTimesApp, pCustomButtonID)
  if not pAppId then pAppId = 1 end
  if not pExpTimesApp then pExpTimesApp = m.isExpected end
  local isExpectedOnButtonEvent = 2
  if pExpTimesApp == m.isNotExpected then isExpectedOnButtonEvent = m.isNotExpected end
  m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONDOWN", appID = m.getHMIAppId(pAppId), customButtonID = pCustomButtonID })
  m.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = pButtonName, mode = "SHORT", appID = m.getHMIAppId(pAppId), customButtonID = pCustomButtonID })
  m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, mode = "BUTTONUP", appID = m.getHMIAppId(pAppId), customButtonID = pCustomButtonID })
  m.getMobileSession(pAppId):ExpectNotification( "OnButtonEvent",
    { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN", customButtonID = pCustomButtonID },
    { buttonName = pButtonName, buttonEventMode = "BUTTONUP",  customButtonID = pCustomButtonID })
  :Times(isExpectedOnButtonEvent)
  m.getMobileSession(pAppId):ExpectNotification( "OnButtonPress",
    { buttonName = pButtonName, buttonPressMode = "SHORT",  customButtonID = pCustomButtonID })
  :Times(pExpTimesApp)
end

--[[ @buttonPressMultipleApps: performs press button for Apps
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pButtonName - button name
--! pExpTimesApp1: number of notifications for 1st app
--! pExpTimesApp2: number of notifications for 2nd app
--! @return: none
--]]
function m.buttonPressMultipleApps(pAppId, pButtonName, pExpTimesApp1, pExpTimesApp2)
  local appSessionId1 = 1
  local appSessionId2 = 2
  local isExpectedOnButtonEventApp1 = 2
  local isExpectedOnButtonEventApp2 = 2
  if pExpTimesApp1 == m.isNotExpected then isExpectedOnButtonEventApp1 = m.isNotExpected end
  if pExpTimesApp2 == m.isNotExpected then isExpectedOnButtonEventApp2 = m.isNotExpected end
  m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, appID = m.getHMIAppId(pAppId), mode = "BUTTONDOWN" })
  m.getHMIConnection():SendNotification("Buttons.OnButtonPress",
    { name = pButtonName, appID = m.getHMIAppId(pAppId), mode = "SHORT" })
  m.getHMIConnection():SendNotification("Buttons.OnButtonEvent",
    { name = pButtonName, appID = m.getHMIAppId(pAppId), mode = "BUTTONUP" })
  m.getMobileSession(appSessionId1):ExpectNotification( "OnButtonEvent",
    { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN"},
    { buttonName = pButtonName, buttonEventMode = "BUTTONUP"})
  :Times(isExpectedOnButtonEventApp1)
  m.getMobileSession(appSessionId1):ExpectNotification( "OnButtonPress",
    { buttonName = pButtonName, buttonPressMode = "SHORT"})
  :Times(pExpTimesApp1)
  m.getMobileSession(appSessionId2):ExpectNotification( "OnButtonEvent",
    { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN"},
    { buttonName = pButtonName, buttonEventMode = "BUTTONUP"})
  :Times(isExpectedOnButtonEventApp2)
  m.getMobileSession(appSessionId2):ExpectNotification( "OnButtonPress",
    { buttonName = pButtonName, buttonPressMode = "SHORT"})
  :Times(pExpTimesApp2)
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
  m.getHMIConnection():ExpectRequest("Buttons." .. pRpc,{ appID = m.getHMIAppId(pAppId), buttonName = pButtonName })
  :Do(function()
      -- HMI does not respond
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
  m.getHMIConnection():ExpectRequest("Buttons." .. pRpc,{ appID = m.getHMIAppId(pAppId), buttonName = pButtonName })
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
  m.wait(1000)
end

--[[ @checkResumptionData: function to check resumption
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pExpTime - number of expected Buttons.SubscribeButton requests from SDL to HMI
--! @return: none
--]]
function m.checkResumptionData(pAppId, pExpTime)
  if not pExpTime then pExpTime = m.isExpected end
  m.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
    { appID = m.getHMIAppId(pAppId), buttonName = "CUSTOM_BUTTON" })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  :Times(pExpTime)
  m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Times(0)
end

--[[ @reRegisterAppSuccess: re-register application with SUCCESS resultCode
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pCheckResumptionData - verification function for resumption data
--! pExpTime - number of expectations
--! @return: none
--]]
function m.reRegisterAppSuccess(pAppId, pCheckResumptionData, pExpTime)
  if not pAppId then pAppId = 1 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = m.cloneTable(m.getConfigAppParams(pAppId))
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = m.getConfigAppParams(pAppId).appName } })
      mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
    end)
  pCheckResumptionData(pAppId, pExpTime)
  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(pAppId) })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
end

--[[ @ignitionOff: perform ignition off
--! @parameters: none
--! @return: none
--]]
function m.ignitionOff()
  local isOnSDLCloseSent = false
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    m.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    m.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  end)
  m.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then m.cprint(color.magenta, "BC.OnSDLClose was not sent") end
    for i = 1, actions.mobile.getAppsCount() do
      actions.mobile.deleteSession(i)
    end
    StopSDL()
  end)
end

--[[ @reRegisterApp: re-register application with RESUME_FAILED resultCode
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! pCheckResumptionData - verification function for resumption data
--! pRAIResponseExp - time for expectation of RAI response
--! @return: none
--]]
function m.reRegisterApp(pAppId, pCheckResumptionData, pRAIResponseExp)
  if not pAppId then pAppId = 1 end
  if not pRAIResponseExp then pRAIResponseExp = 10000 end
  local mobSession = m.getMobileSession(pAppId)
  mobSession:StartService(7)
  :Do(function()
      local params = m.cloneTable(m.getConfigAppParams(pAppId))
      params.hashID = m.hashId[pAppId]
      local corId = mobSession:SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = m.getConfigAppParams(pAppId).appName } })
      mobSession:ExpectResponse(corId, { success = true, resultCode = "RESUME_FAILED" })
      :Do(function()
          m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = m.getHMIAppId(pAppId) })
          :Do(function(_, data)
              m.getHMIConnection():SendResponse(data.id, "BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          mobSession:ExpectNotification("OnPermissionsChange")
        end)
      :Timeout(pRAIResponseExp)
    end)
  pCheckResumptionData(pAppId)
end

--[[ @removeButtonFromCapabilities: remove button from HMI capabilities
--! @parameters:
--! pButtonName - button name
--! @return: returns HMI Table without button
--]]
function m.removeButtonFromCapabilities(pButtonName)
  local hmiValues = m.getDefaultHMITable()
  for i, buttonNameTab in pairs(hmiValues.Buttons.GetCapabilities.params.capabilities) do
    if (buttonNameTab.name == pButtonName) then
      table.remove(hmiValues.Buttons.GetCapabilities.params.capabilities, i)
    end
  end
  return hmiValues
end

--[[ @addButtonToCapabilities: add button to HMI capabilities
--! @parameters:
--! pButtonCapabilities - button capabilities
--! @return: returns HMI Table with supported button
--]]
function m.addButtonToCapabilities(pButtonCapabilities)
  local hmiValues = m.getDefaultHMITable()
  for i, buttonNameTab in pairs(hmiValues.Buttons.GetCapabilities.params.capabilities) do
    if (buttonNameTab.name == pButtonCapabilities.name) then
      table.remove(hmiValues.Buttons.GetCapabilities.params.capabilities, i)
      break
    end
  end
  table.insert(hmiValues.Buttons.GetCapabilities.params.capabilities, pButtonCapabilities)
  return hmiValues
end

--[[ @removeButtonFromHMICapabilitiesFile: remove button support from hmi_capabilities.json file
--! @parameters:
--! pButtonName - button name
--! @return: none
--]]
function m.removeButtonFromHMICapabilitiesFile(pButtonName)
  local hmiCapTbl = m.getHMICapabilitiesFromFile()
  for i, buttonNameTab in pairs(hmiCapTbl.Buttons.capabilities) do
    if (buttonNameTab.name == pButtonName) then
      table.remove(hmiCapTbl.Buttons.capabilities, i)
      break
    end
  end
  m.setHMICapabilitiesToFile(hmiCapTbl)
end

--[[ @addButtonToHMICapabilitiesFile: add button support to hmi_capabilities.json file
--! @parameters:
--! pButtonCapabilities - button capabilities
--! @return: none
--]]
function m.addButtonToHMICapabilitiesFile(pButtonCapabilities)
  local hmiCapTbl = m.getHMICapabilitiesFromFile()
  for i, buttonNameTab in pairs(hmiCapTbl.Buttons.capabilities) do
    if (buttonNameTab.name == pButtonCapabilities.name) then
      table.remove(hmiCapTbl.Buttons.capabilities, i)
      break
    end
  end
  table.insert(hmiCapTbl.Buttons.capabilities, pButtonCapabilities)
  m.setHMICapabilitiesToFile(hmiCapTbl)
end

--[[ @registerAppSubCustomButton: register App with subscription to "CUSTOM_BUTTON"
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! pResultCode - result code
--! pExpRequest - count of expected Buttons.SubscribeButton requests from SDL to HMI)
--! @return: none
--]]
function m.registerAppSubCustomButton(pAppId, pResultCode, pExpRequest)
  if not pAppId then pAppId = 1 end
  if not pResultCode then pResultCode = "SUCCESS" end
  if not pExpRequest then pExpRequest = 1 end
  local session = actions.mobile.createSession(pAppId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", actions.app.getParams(pAppId))
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = actions.app.getParams(pAppId).appName } })
      :Do(function(_, d1)
          actions.app.setHMIId(d1.params.application.appID, pAppId)
          m.getHMIConnection():ExpectRequest("Buttons.SubscribeButton",
            { appID = m.getHMIAppId(pAppId), buttonName = "CUSTOM_BUTTON" })
          :Do(function(_, data)
              m.getHMIConnection():SendResponse(data.id, data.method, pResultCode, { })
            end)
          :Times(pExpRequest)
          m.getMobileSession(pAppId):ExpectNotification("OnHashChange")
          :Times(0)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE" })
        end)
    end)
end

--[[ @registerSoftButton: send Show request with soft button
--! @parameters: none
--! @return: none
--]]
function m.registerSoftButton()
  local requestParams = {
    softButtons = {
      {
        text = "Button1",
        systemAction = "DEFAULT_ACTION",
        type = "TEXT",
        isHighlighted = false,
        softButtonID = m.customButtonID
      }
    }
  }
  local cid = m.getMobileSession():SendRPC("Show", requestParams)
  m.getHMIConnection():ExpectRequest("UI.Show")
  :Do(function(_,data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ @getUpdatedHMICaps: update HMI capabilities
--! @parameters:
--! pVersion - 'ccpu_version' parameter for GetSystemInfo response
--! pHMIParams - parameters with HMI capabilities
--! @return: returns HMI Table with updated parameters
--]]
function m.getUpdatedHMICaps(pVersion, pHMIParams)
  if not pHMIParams then pHMIParams = m.getDefaultHMITable end
  local hmiValues = pHMIParams
  hmiValues.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = pVersion,
      language = "EN-US",
      wersCountryCode = "wersCountryCode"
    }
  }
  return hmiValues
end

return m
