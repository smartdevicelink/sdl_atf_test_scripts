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
local common = actions

common.readFile = utils.readFile

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

function common.HandshakeMessageError(handshakeResponse, expErrorNotification)
  local session = common.getMobileSession().mobile_session_impl.control_services.session
  local handshakeEvent = events.Event()
  handshakeEvent.matches = function(_, data)
      return data.frameType ~= constants.FRAME_TYPE.CONTROL_FRAME
        and data.serviceType == constants.SERVICE_TYPE.CONTROL
        and data.sessionId == session.sessionId.get()
        and data.rpcFunctionId == constants.BINARY_RPC_FUNCTION_ID.HANDSHAKE
    end
  session:ExpectEvent(handshakeEvent, "Handshake internal")
  :Do(function(_, data)
      if not handshakeResponse.rpcCorrelationId then
        handshakeResponse.rpcCorrelationId = data.rpcCorrelationId
      end
      if not handshakeResponse.binaryData then
        local binData = data.binaryData
        local dataToSend = session.security:performHandshake(binData)
        handshakeResponse.binaryData = dataToSend
      end

      session:Send(handshakeResponse)
    end)
  :Times(AnyNumber())

  if expErrorNotification then
    expectSecurityQuery(expErrorNotification)
  end
end

function common.expectSecurityQuery(params)
  local session = common.getMobileSession().mobile_session_impl.control_services.session
  local queryEvent = events.Event()
  queryEvent.matches = function(_, data)
      return data.frameType ~= constants.FRAME_TYPE.CONTROL_FRAME
        and (not data.rpcType or data.rpcType == params.rpcType)
        and data.serviceType == constants.SERVICE_TYPE.CONTROL
        and data.sessionId == session.sessionId.get()
        and data.rpcFunctionId == params.rpcFunctionId
    end
  session:ExpectEvent(queryEvent, "Error internal")
  :ValidIf(function(exp, data)
      return compareValues(params, data, "data")
    end)
end

local function registerGetSystemTimeResponse()
  actions.getHMIConnection():ExpectRequest("BasicCommunication.GetSystemTime")
  :Do(function(_, data)
      actions.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { systemTime = getSystemTimeValue() })
    end)
  :Pin()
  :Times(AnyNumber())
end

function common.allowSDL()
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
  common.getHMIConnection():SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
  RUN_AFTER(function() common.getHMIConnection():RaiseEvent(event, "Allow SDL event") end, 500)
  return common.getHMIConnection():ExpectEvent(event, "Allow SDL event")
end

function common.start(pHMIParams, isCacheUsed)
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
                      common.allowSDL()
                    end)
                end)
            end)
        end)
    end)
end

function common.initSDLCertificates(pCrtsFileName, pIsModuleCrtDefined)
  SDL.CRT.set(pCrtsFileName, pIsModuleCrtDefined)
end

function common.cleanUpCertificates()
  SDL.CRT.clean()
end

local preconditionsOrig = common.preconditions
local postconditionsOrig = common.postconditions

function common.preloadedPTUpdate(pPTUpdateFunc)
  local pt = actions.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  if pPTUpdateFunc then pPTUpdateFunc(pt) end
  actions.sdl.setPreloadedPT(pt)
end

function common.preconditions(pPTUpdateFunc)
  preconditionsOrig()
  common.setSDLIniParameter("Protocol", "DTLSv1.0")
  common.cleanUpCertificates()
  if pPTUpdateFunc == nil then
    pPTUpdateFunc = function(pPT)
      pPT.policy_table.app_policies["default"].encryption_required = true
    end
  end
  common.preloadedPTUpdate(pPTUpdateFunc)
end

function common.postconditions()
  postconditionsOrig()
  common.cleanUpCertificates()
end

function common.defaultExpNotificationFunc()
  common.getHMIConnection():ExpectRequest("BasicCommunication.DecryptCertificate")
  :Do(function(_, d)
      common.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { })
    utils.wait(1000) -- time for SDL to save certificates
    end)
  :Times(AnyNumber())
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
end

local policyTableUpdateOrig = common.policyTableUpdate
function common.policyTableUpdate(pPTUpdateFunc, pExpNotificationFunc)
  local func = common.defaultExpNotificationFunc
  if pExpNotificationFunc then func = pExpNotificationFunc end
  policyTableUpdateOrig(pPTUpdateFunc, func)
end

function common.policyTableUpdateSuccess(pPTUpdateFunc)  
  common.isPTUStarted()  
  :Do(function()  
      common.policyTableUpdate(pPTUpdateFunc)  
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

return common