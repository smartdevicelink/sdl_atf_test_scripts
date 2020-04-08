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
local functionId = require('function_id')
local apiLoader = require("modules/api_loader")
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local m = {}
local hashId = {}
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

--[[ Shared Functions ]]
m.Title = runner.Title
m.Step = runner.Step
m.cloneTable = utils.cloneTable
m.wait = utils.wait
m.EMPTY_ARRAY = json.EMPTY_ARRAY
m.start = actions.start
m.registerApp = actions.registerApp
m.registerAppWOPTU = actions.registerAppWOPTU
m.activateApp = actions.activateApp
m.policyTableUpdate = actions.policyTableUpdate
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.getHMIAppId = actions.getHMIAppId
m.getAppsCount = actions.getAppsCount
m.getConfigAppParams = actions.getConfigAppParams
m.setSDLIniParameter = actions.setSDLIniParameter

--[[ Common Functions ]]

--[[ @getShowParams: Provide default parameters for 'Show' RPC
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: parameters for 'Show' RPC
--]]
function m.getShowParams(pAppId)
  return {
    requestShowParams = {
      mainField1 = "Text_1",
      graphic = {
        imageType = "DYNAMIC",
        value = "icon.png"
      }
    },
    requestShowUiParams = {
      showStrings = {
        {
          fieldName = "mainField1",
          fieldText = "Text_1"
        }
      },
      graphic = {
        imageType = "DYNAMIC",
        value = actions.getPathToFileInStorage("icon.png", pAppId)
      }
    }
  }
end

--[[ @getOnSystemCapabilityParams: Provide default parameters for 'OnSystemCapabilityParams' RPC
--! @parameters:
--! pMaxNumOfWidgetWindows: maximum number of widget windows
--! @return: parameters for 'OnSystemCapabilityParams' RPC
--]]
function m.getOnSystemCapabilityParams(pMaxNumOfWidgetWindows)
  if not pMaxNumOfWidgetWindows then pMaxNumOfWidgetWindows = 5 end
  return {
    systemCapability = {
      systemCapabilityType = "DISPLAYS",
      displayCapabilities = {
        {
          displayName = "displayName",
          windowTypeSupported = {
            {
              type = "MAIN",
              maximumNumberOfWindows = 1
            },
            {
              type = "WIDGET",
              maximumNumberOfWindows = pMaxNumOfWidgetWindows
            }
          },
          windowCapabilities = {
            {
              windowID = 1,
              textFields = {
                {
                  name = "mainField1",
                  characterSet = "TYPE2SET",
                  width = 1,
                  rows = 1
                }
              },
              imageFields = {
                {
                  name = "choiceImage",
                  imageTypeSupported = { "GRAPHIC_PNG"
                  },
                  imageResolution = {
                    resolutionWidth = 35,
                    resolutionHeight = 35
                  }
                }
              },
              imageTypeSupported = {
                "STATIC"
              },
              templatesAvailable = {
                "Template1", "Template2", "Template3", "Template4", "Template5"
              },
              numCustomPresetsAvailable = 100,
              buttonCapabilities = {
                {
                  longPressAvailable = true,
                  name = "VOLUME_UP",
                  shortPressAvailable = true,
                  upDownAvailable = false
                }
              },
              softButtonCapabilities = {
                {
                  shortPressAvailable = true,
                  longPressAvailable = true,
                  upDownAvailable = true,
                  imageSupported = true,
                  textSupported = true
                }
              }
            }
          }
        }
      }
    }
  }
end

--[[ @setHashId: Set hashId which is required during resumption
--! @parameters:
--! pHashId: application hashId
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.setHashId(pHashId, pAppId)
  hashId[pAppId] = pHashId
end

--[[ @getHashId: Get hashId of an app which is required during resumption
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: app's hashId
--]]
function m.getHashId(pAppId)
  return hashId[pAppId]
end

--[[ @updatePreloadedPT: Update preloaded file with additional permissions
--! @parameters: none
--! @return: none
--]]
local function updatePreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  local WidgetSupport = {
    rpcs = {
      CreateWindow = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" }
      },
      DeleteWindow = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" }
      }
    }
  }
  pt.policy_table.app_policies["default"].groups = { "Base-4", "WidgetSupport" }
  pt.policy_table.app_policies["default"].steal_focus = true
  pt.policy_table.functional_groupings["WidgetSupport"] = WidgetSupport
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  utils.tableToJsonFile(pt, preloadedFile)
end

function m.precondition()
  actions.preconditions()
  commonPreconditions:BackupFile(preloadedPT)
  updatePreloadedPT()
end

function m.postcondition()
  for i = 1, m.getAppsCount() do
    test.mobileSession[i]:StopRPC()
    :Do(function(_, d)
        utils.cprint(35, "Mobile session " .. d.sessionId .. " deleted")
        test.mobileSession[i] = nil
      end)
  end
  utils.wait()
  :Do(function()
      actions.postconditions()
      commonPreconditions:RestoreFile(preloadedPT)
    end)
end

--[[ @createWindow: Processing CreateWindow RPC
--! @parameters:
--! pParams: Parameters for CreateWindow RPC
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.createWindow(pParams, pAppId)
  local params = m.cloneTable(pParams)
  if not pAppId then pAppId = 1 end
  local cid = m.getMobileSession(pAppId):SendRPC("CreateWindow", params)
  params.appID = m.getHMIAppId(pAppId)
  m.getHMIConnection():ExpectRequest("UI.CreateWindow", params)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      local paramsToSDL = m.getOnSystemCapabilityParams()
      paramsToSDL.appID = m.getHMIAppId(pAppId)
      m.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", paramsToSDL)
      m.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated", m.getOnSystemCapabilityParams())
    end)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", windowID = params.windowID })
end

--[[ @createWindowUnsuccess: Processing CreateWindow with ERROR resultCode
--! @parameters:
--! pParams: Parameters for CreateWindow RPC
--! pResultCode - result error
--! @return: none
--]]
function m.createWindowUnsuccess(pParams, pResultCode)
  local cid = m.getMobileSession():SendRPC("CreateWindow", pParams)
  m.getHMIConnection():ExpectRequest("UI.CreateWindow")
  :Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
  m.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated")
  :Times(0)
  m.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

--[[ @deleteWindow: Processing DeleteWindow RPC
--! @parameters:
--! @pWindowID: Parameters for DeleteWindow RPC
--! @return: none
--]]
function m.deleteWindow(pWindowID)
  local cid = m.getMobileSession():SendRPC("DeleteWindow", { windowID = pWindowID })
  m.getHMIConnection():ExpectRequest("UI.DeleteWindow", { windowID = pWindowID })
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated")
  :Times(0)
end

--[[ @deleteWindowUnsuccess: Processing DeleteWindow with ERROR resultCode
--! @parameters:
--! @pWindowID: Parameters for DeleteWindow RPC
--! pResultCode - result error
--! @return: none
--]]
function m.deleteWindowUnsuccess(pWindowID, pResultCode)
  local cid = m.getMobileSession():SendRPC("DeleteWindow", { windowID = pWindowID })
  m.getHMIConnection():ExpectRequest("UI.DeleteWindow")
  :Times(0)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
  m.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated")
  :Times(0)
end

--[[ @deleteWindowHMIwithoutResponse: performs case when HMI did not respond
--! @parameters:
--! @pWindowID: Parameters for DeleteWindow RPC
--! pResultCode - result error
--! @return: none
--]]
function m.deleteWindowHMIwithoutResponse(pWindowID, pResultCode)
  local cid = m.getMobileSession():SendRPC("DeleteWindow", { windowID = pWindowID })
  m.getHMIConnection():ExpectRequest("UI.DeleteWindow", { windowID = pWindowID })
  :Do(function()
      -- HMI did not response
    end)
  m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = pResultCode })
  m.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated")
  :Times(0)
end

--[[ @sendShowToWindow: Processing Show RPC to a main and a widget windows
--! @parameters:
--! @pWindowID: Parameters for Show RPC
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.sendShowToWindow(pWindowId, pAppId)
  if not pAppId then pAppId = 1 end
  local params = m.getShowParams(pAppId)
  if pWindowId then
    params.requestShowParams.windowID = pWindowId
    params.requestShowUiParams.windowID = pWindowId
  end
  params.requestShowUiParams.appID = m.getHMIAppId(pAppId)
  local cid = m.getMobileSession(pAppId):SendRPC("Show", params.requestShowParams)
  m.getHMIConnection():ExpectRequest("UI.Show", params.requestShowUiParams)
  :ValidIf(function(_,data)
      if pWindowId == nil and data.windowID ~= nil then
        return false, "SDL sends not exist window ID to HMI"
      else
        return true
      end
    end)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      if params.requestShowParams.templateConfiguration ~= nil then
        local paramsToSDL = m.getOnSystemCapabilityParams()
        paramsToSDL.appID = m.getHMIAppId(pAppId)
        m.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", paramsToSDL)
        m.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated", m.getOnSystemCapabilityParams())
      else
        m.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated")
        :Times(0)
      end
    end)
end

--[[ @sendShowToWindowUnsuccess: Processing Show RPC with ERROR resultCode
--! @parameters:
--! @pWindowID: Parameters for Show RPC
--! pResultCode - result error
--! @return: none
--]]
function m.sendShowToWindowUnsuccess(pWindowId, pResultCode, pAppId)
  if not pAppId then pAppId = 1 end
  local params = m.getShowParams(pAppId)
  if pWindowId then
    params.requestShowParams.windowID = pWindowId
  end
  local cid = m.getMobileSession(pAppId):SendRPC("Show", params.requestShowParams)
  m.getHMIConnection():ExpectRequest("UI.Show")
  :Times(0)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = pResultCode })
  m.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated")
  :Times(0)
end

--[[ @sendShowToWindowUnsuccessHMIREJECTED: Processing Show RPC with REJECTED HMI response
--! @parameters:
--! @pWindowID: Parameters for Show RPC
--! pResultCode - result error
--! @return: none
--]]
function m.sendShowToWindowUnsuccessHMIREJECTED(pWindowId, pAppId)
  if not pAppId then pAppId = 1 end
  local params = m.getShowParams(pAppId)
  if pWindowId then
    params.requestShowParams.windowID = pWindowId
    params.requestShowUiParams.windowID = pWindowId
  end
  params.requestShowUiParams.appID = m.getHMIAppId(pAppId)
  local cid = m.getMobileSession(pAppId):SendRPC("Show", params.requestShowParams)
  m.getHMIConnection():ExpectRequest("UI.Show", params.requestShowUiParams)
  :Do(function(_, data)
      m.getHMIConnection():SendError(data.id, data.method, "REJECTED", "Error code")
      m.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated")
      :Times(0)
    end)
  m.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
end

local function checkAbsenceOfOnHMIStatusForOtherApps(pAppId)
  for i = 1, m.getAppsCount() do
    if i ~= pAppId then
      m.getMobileSession(i):ExpectNotification("OnHMIStatus")
      :Times(0)
    end
  end
end

--[[ @activateWidgetFromNoneToFULL: Activate widget from NONE to FULL
--! @parameters:
--! pId: widget id (1, 2, etc.)
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.activateWidgetFromNoneToFULL(pId, pAppId)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppActivated",
    { appID = m.getHMIAppId(pAppId), windowID = pId })
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppActivated",
    { appID = m.getHMIAppId(pAppId), windowID = pId })
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", windowID = pId},
    { hmiLevel = "FULL", windowID = pId })
  :Times(2)
  checkAbsenceOfOnHMIStatusForOtherApps(pAppId)
end

--[[ @activateWidgetFromBackgroundToFULL: Activate widget from BACKGROUND to FULL
--! @parameters:
--! pId: widget id (1, 2, etc.)
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.activateWidgetFromBackgroundToFULL(pId, pAppId)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppActivated",
    { appID = m.getHMIAppId(pAppId), windowID = pId })
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", windowID = pId })
  checkAbsenceOfOnHMIStatusForOtherApps(pAppId)
end

--[[ @deactivateWidgetFromFullToNone: Deactivate widget from FULL to NONE
--! @parameters:
--! pId: widget id (1, 2, etc.)
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.deactivateWidgetFromFullToNone(pId, pAppId)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = m.getHMIAppId(pAppId), windowID = pId })
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = m.getHMIAppId(pAppId), windowID = pId })
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", windowID = pId },
    { hmiLevel = "NONE", windowID = pId })
  :Times(2)
  checkAbsenceOfOnHMIStatusForOtherApps(pAppId)
end

--[[ @deactivateWidgetFromFullToBackground: Deactivate widget from FULL to BACKGROUND
--! @parameters:
--! pId: widget id (1, 2, etc.)
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.deactivateWidgetFromFullToBackground(pId, pAppId)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = m.getHMIAppId(pAppId), windowID = pId })
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", windowID = pId })
  checkAbsenceOfOnHMIStatusForOtherApps(pAppId)
end

--[[ @deactivateAppFromFullToNone: Deactivate app from FULL to NONE
--! @parameters:
--! pAppId: application number (1, 2, etc.)
--! @return: none
--]]
function m.deactivateAppFromFullToNone(pAppId)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
    { appID = m.getHMIAppId(pAppId), reason = "USER_EXIT" })
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
  :Times(AtLeast(1))
  checkAbsenceOfOnHMIStatusForOtherApps(pAppId)
end

--[[ @unexpectedDisconnect: closing connection
--! @parameters: none
--! @return: none
--]]
function m.unexpectedDisconnect()
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Times(actions.mobile.getAppsCount())
  actions.mobile.disconnect()
  utils.wait(1000)
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

--[[ @ignitionOff: IGNITION_OFF sequence
--! @parameters: none
--! @return: none
--]]
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

--[[ @expCreateWindowResponse: expectation of CreateWindow response
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: Expectation for event
--]]
function m.expCreateWindowResponse(pAppId)
  local event = events.Event()
  event.matches = function(_, data) return data.rpcFunctionId == functionId["CreateWindow"] end
  return m.getMobileSession(pAppId):ExpectEvent(event, "CreateWindow response")
end

--[[ @getOnSCUParams: provide parameters for 'OnSystemCapabilityUpdated' notification
--! @parameters:
--! pWindowsArray - array of windows (e.g. {0, 2, 4})
--! pWindowId - window id (1, 2, etc.)
--! @return: parameters for notification
--]]
function m.getOnSCUParams(pWindowsArray, pWindowId)
  local params = m.getOnSystemCapabilityParams()
  local disCaps = params.systemCapability.displayCapabilities[1]
  local defWinCaps = m.cloneTable(disCaps.windowCapabilities[1])
  disCaps.windowCapabilities = {}
  for _, winId in pairs(pWindowsArray) do
    local specificWinCaps = m.cloneTable(defWinCaps)
    specificWinCaps.windowID = winId
    specificWinCaps.templatesAvailable = { "Template_" .. winId }
    table.insert(disCaps.windowCapabilities, specificWinCaps)
  end
  if pWindowId ~= nil then
    for _, winCap in pairs(disCaps.windowCapabilities) do
      if winCap.windowID == pWindowId then
        disCaps.windowCapabilities = { winCap }
      end
    end
  end
  return params
end

--[[ @sendOnSCU: send 'BC.OnSystemCapabilityUpdated' notification from HMI
--! @parameters:
--! pParams - parameters for the notification
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.sendOnSCU(pParams, pAppId)
  local params = m.cloneTable(pParams)
  params.appID = m.getHMIAppId(pAppId)
  m.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", params)
end

--[[ @checkResumption: function to check resumption
--! @parameters:
--! pWidgetParams - widget window parameters
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
local function checkResumption(pWidgetParams, pAppId)
  local winCaps = m.getOnSCUParams({ 0, pWidgetParams.windowID })
  m.getMobileSession(pAppId):ExpectNotification("OnSystemCapabilityUpdated", winCaps)
  m.getHMIConnection():ExpectRequest("UI.CreateWindow", pWidgetParams)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      m.sendOnSCU(m.getOnSCUParams({ 0, pWidgetParams.windowID }, pWidgetParams.windowID), pAppId)
    end)
  m.expCreateWindowResponse(pAppId)
  :Times(0)
end

--[[ @checkResumption_NONE: function to check resumption for app in NONE HMI level
--! @parameters:
--! pWidgetParams - widget window parameters
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.checkResumption_NONE(pWidgetParams, pAppId)
  m.getHMIConnection():ExpectRequest("BasicCommunication.CloseApplication", {})
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { windowID = 0, hmiLevel = "NONE" },
    { windowID = pWidgetParams.windowID, hmiLevel = "NONE" })
  :Times(2)
  checkResumption(pWidgetParams, pAppId)
end

--[[ @checkResumption_LIMITED: function to check resumption for app in LIMITED HMI level
--! @parameters:
--! pWidgetParams - widget window parameters
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.checkResumption_LIMITED(pWidgetParams, pAppId)
  m.getHMIConnection():ExpectNotification("BasicCommunication.OnResumeAudioSource", { appID = m.getHMIAppId(pAppId) })
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { windowID = 0, hmiLevel = "NONE" },
    { windowID = 0, hmiLevel = "LIMITED" },
    { windowID = pWidgetParams.windowID, hmiLevel = "NONE" })
  :Times(3)
  checkResumption(pWidgetParams, pAppId)
end

--[[ @checkResumption_FULL: function to check resumption for app in FULL HMI level
--! @parameters:
--! pWidgetParams - widget window parameters
--! pAppId - application number (1, 2, etc.)
--! @return: none
--]]
function m.checkResumption_FULL(pWidgetParams, pAppId)
  m.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { windowID = 0, hmiLevel = "NONE" },
    { windowID = 0, hmiLevel = "FULL" },
    { windowID = pWidgetParams.windowID, hmiLevel = "NONE" })
  :Times(3)
  checkResumption(pWidgetParams, pAppId)
end

--[[ @reRegisterAppSuccess: re-register application with SUCCESS resultCode
--! @parameters:
--! pWidgetParams - widget window parameters
--! pAppId - application number (1, 2, etc.)
--! pCheckFunc: check function
--! @return: none
--]]
function m.reRegisterAppSuccess(pWidgetParams, pAppId, pCheckFunc, pResultCode)
  if not pAppId then pAppId = 1 end
  if not pResultCode then pResultCode = "SUCCESS" end
  m.getMobileSession(pAppId):StartService(7)
  :Do(function()
      local params = m.cloneTable(m.getConfigAppParams(pAppId))
      params.hashID = m.getHashId(pAppId)
      local corId = m.getMobileSession(pAppId):SendRPC("RegisterAppInterface", params)
      m.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", {
        application = { appName = m.getConfigAppParams(pAppId).appName }
      })
      :Do(function()
          m.sendOnSCU(m.getOnSCUParams({ 0 }, 0), pAppId)
        end)
      m.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = pResultCode })
      :Do(function()
          m.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
        end)
    end)
  pCheckFunc(pWidgetParams, pAppId)
end

function m.spairs(pTbl)
  local keys = {}
  for k in pairs(pTbl) do
    keys[#keys+1] = k
  end
  local function getStringKey(pKey)
    return tostring(string.format("%03d", pKey))
  end
  table.sort(keys, function(a, b) return getStringKey(a) < getStringKey(b) end)
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], pTbl[keys[i]]
    end
  end
end

local function setSyncMsgVersion()
  local mobile = apiLoader.init("data/MOBILE_API.xml")
  local schema = mobile.interface[next(mobile.interface)]
  local ver = schema.version
  for appId = 1, 3 do
    local syncMsgVersion = m.getConfigAppParams(appId).syncMsgVersion
    syncMsgVersion.majorVersion = tonumber(ver.majorVersion)
    syncMsgVersion.minorVersion = tonumber(ver.minorVersion)
    syncMsgVersion.patchVersion = tonumber(ver.patchVersion)
  end
end

setSyncMsgVersion()

return m
