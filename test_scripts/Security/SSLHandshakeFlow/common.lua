---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local security = require("user_modules/sequences/security")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local SDL = require("SDL")
local constants = require("protocol_handler/ford_protocol_constants")
local events = require("events")
local json = require("modules/json")

--[[ General configuration parameters ]]
config.SecurityProtocol = "DTLS"
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.fullAppID = "SPT"

--[[ Module ]]
local m = actions

m.frameInfo = security.frameInfo
m.readFile = utils.readFile

--[[ Functions ]]
local function getSystemTimeValue()
  local dd = os.date("*t")
  return {
    millisecond = 0,
    second = dd.sec,
    minute = dd.min,
    hour = dd.hour,
    day = dd.day,
    month = dd.month,
    year = dd.year,
    tz_hour = 2,
    tz_minute = 0
  }
end

local function registerGetSystemTimeResponse()
  actions.getHMIConnection():ExpectRequest("BasicCommunication.GetSystemTime")
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { systemTime = getSystemTimeValue() })
    end)
  :Pin()
  :Times(AnyNumber())
end

function m.allowSDL()
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
  m.getHMIConnection():SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
  RUN_AFTER(function() m.getHMIConnection():RaiseEvent(event, "Allow SDL event") end, 500)
  return m.getHMIConnection():ExpectEvent(event, "Allow SDL event")
end

function m.start(pHMIParams, isCacheUsed)
  test:runSDL()
  SDL.WaitForSDLStart(test)
  :Do(function()
      test:initHMI()
      :Do(function()
          local rid = actions.getHMIConnection():SendRequest("MB.subscribeTo", {
            propertyName = "BasicCommunication.OnSystemTimeReady" })
          actions.getHMIConnection():ExpectResponse(rid)
          :Do(function()
              utils.cprint(35, "HMI initialized")
              test:initHMI_onReady(pHMIParams, isCacheUsed)
              :Do(function()
                  utils.cprint(35, "HMI is ready")
                  actions.getHMIConnection():SendNotification("BasicCommunication.OnSystemTimeReady")
                  registerGetSystemTimeResponse()
                  test:connectMobile()
                  :Do(function()
                      utils.cprint(35, "Mobile connected")
                      m.allowSDL()
                    end)
                end)
            end)
        end)
    end)
end

function m.sendAddCommandProtected()
  local params = {
    cmdID = 1,
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local cid = m.getMobileSession():SendEncryptedRPC("AddCommand", params)
  m.getHMIConnection():ExpectRequest("UI.AddCommand", params)
  :Do(function(_, data)
      m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  m.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  m.getMobileSession():ExpectEncryptedNotification("OnHashChange")
end

function m.activateAppProtected()
  local rid = m.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = m.getHMIAppId() })
  m.getHMIConnection():ExpectResponse(rid)
  m.getMobileSession():ExpectEncryptedNotification("OnHMIStatus", {
    hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

function m.initSDLCertificates(pCrtsFileName, pIsModuleCrtDefined)
  SDL.CRT.set(pCrtsFileName, pIsModuleCrtDefined)
end

function m.cleanUpCertificates()
  SDL.CRT.clean()
end

local preconditionsOrig = m.preconditions
local postconditionsOrig = m.postconditions

function m.preloadedPTUpdate(pPTUpdateFunc)
  local pt = actions.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  if pPTUpdateFunc then pPTUpdateFunc(pt) end
  actions.sdl.setPreloadedPT(pt)
end

function m.preconditions(pPTUpdateFunc)
  preconditionsOrig()
  m.setSDLIniParameter("Protocol", "DTLSv1.0")
  m.cleanUpCertificates()
  if pPTUpdateFunc == nil then
    pPTUpdateFunc = function(pPT)
      pPT.policy_table.app_policies["default"].encryption_required = true
      pPT.policy_table.functional_groupings["Base-4"].encryption_required = true
    end
  end
  m.preloadedPTUpdate(pPTUpdateFunc)
end

function m.postconditions()
  postconditionsOrig()
  m.cleanUpCertificates()
end

function m.defaultExpNotificationFunc()
  m.getHMIConnection():ExpectRequest("BasicCommunication.DecryptCertificate")
  :Do(function(_, d)
      m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { })
    utils.wait(1000) -- time for SDL to save certificates
    end)
  :Times(AnyNumber())
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
end

local policyTableUpdateOrig = m.policyTableUpdate
function m.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc)
  local func = m.defaultExpNotificationFunc
  if pExpNotificationFunc then func = pExpNotificationFunc end
  policyTableUpdateOrig(pPTUpdateFunc, func)
end

function m.policyTableUpdateSuccess(pPTUpdateFunc)
  m.isPTUStarted()
  :Do(function()
      m.policyTableUpdate(pPTUpdateFunc)
    end)
end

local function registerStartSecureServiceFunc(pMobSession)
  function pMobSession.mobile_session_impl.control_services:StartSecureService(pServiceId, pPayload)
    local msg = {
      serviceType = pServiceId,
      frameInfo = constants.FRAME_INFO.START_SERVICE,
      sessionId = self.session.sessionId.get(),
      encryption = true,
      binaryData = pPayload
    }
    self:Send(msg)
  end
  function pMobSession.mobile_session_impl:StartSecureService(pServiceId, pPayload)
    if not self.isSecuredSession then
      self.security:registerSessionSecurity()
      self.security:prepareToHandshake()
    end
    return self.control_services:StartSecureService(pServiceId, pPayload)
  end
  function pMobSession:StartSecureService(pServiceId, pPayload)
    return self.mobile_session_impl:StartSecureService(pServiceId, pPayload)
  end
end

local origGetMobileSession = actions.getMobileSession
function actions.getMobileSession(pAppId)
  if not pAppId then pAppId = 1 end
  if not test.mobileSession[pAppId] then
    local session = origGetMobileSession(pAppId)
    registerStartSecureServiceFunc(session)
  end
  return origGetMobileSession(pAppId)
end

return m
