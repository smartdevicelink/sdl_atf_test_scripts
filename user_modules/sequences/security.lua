---------------------------------------------------------------------------------------------------
-- Security common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.serverCertificatePath = "./files/Security/spt_credential.pem"
config.serverPrivateKeyPath = "./files/Security/spt_credential.pem"
config.serverCAChainCertPath = "./files/Security/spt_credential.pem"

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local events = require("events")
local constants = require("protocol_handler/ford_protocol_constants")

--[[ Module ]]
local m = {}

--[[ Constants ]]
m.frameInfo = constants.FRAME_INFO

--[[ Variables ]]
local origGetMobileSession = actions.getMobileSession

--[[ Functions ]]

--[[ @registerStartSecureServiceFunc: register function to start secure service
--! @parameters:
--! pMobSession - mobile session
--! @return: none
--]]
local function registerStartSecureServiceFunc(pMobSession)
  function pMobSession.mobile_session_impl.control_services:StartSecureService(pServiceId, pData)
    local msg = {
      serviceType = pServiceId,
      frameInfo = constants.FRAME_INFO.START_SERVICE,
      sessionId = self.session.sessionId.get(),
      encryption = true,
      binaryData = pData
    }
    self:Send(msg)
  end
  function pMobSession.mobile_session_impl:StartSecureService(pServiceId, pData)
    if not self.isSecuredSession then
      self.security:registerSessionSecurity()
      self.security:prepareToHandshake()
    end
    return self.control_services:StartSecureService(pServiceId, pData)
  end
  function pMobSession:StartSecureService(pServiceId, pData)
    return self.mobile_session_impl:StartSecureService(pServiceId, pData)
  end
end

--[[ @registerExpectServiceEventFunc: register functions for expectations of control messages:
--! Service Start ACK/NACK and Handshake
--! @parameters:
--! pMobSession - mobile session
--! @return: none
--]]
local function registerExpectServiceEventFunc(pMobSession)
  function pMobSession:ExpectControlMessage(pServiceId, pData)
    local session = self.mobile_session_impl.control_services.session
    local event = events.Event()
    event.matches = function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
      data.serviceType == pServiceId and
      (pServiceId == constants.SERVICE_TYPE.RPC or data.sessionId == session.sessionId.get()) and
      (data.frameInfo == constants.FRAME_INFO.START_SERVICE_ACK or
        data.frameInfo == constants.FRAME_INFO.START_SERVICE_NACK)
    end
    local ret = session:ExpectEvent(event, "StartService")
    :Do(function(_, data)
        if data.encryption == true and data.frameInfo == constants.FRAME_INFO.START_SERVICE_ACK then
          session.security:registerSecureService(pServiceId)
          if data.serviceType == constants.SERVICE_TYPE.RPC then
            session.security:registerSecureService(constants.SERVICE_TYPE.BULK_DATA)
          end
        end
      end)
    :ValidIf(function(_, data)
        if data.encryption ~= pData.encryption then
          return false, "Expected 'encryption' flag is '" .. tostring(pData.encryption)
            .. "', actual is '" .. tostring(data.encryption) .. "'"
        end
        return true
      end)
    :ValidIf(function(_, data)
        if data.frameInfo ~= pData.frameInfo then
          return false, "Expected 'frameInfo' is '" .. tostring(pData.frameInfo)
            .. "', actual is '" .. tostring(data.frameInfo) .. "'"
        end
        return true
      end)
    return ret
  end

  function pMobSession:ExpectHandshakeMessage()
    local session = self.mobile_session_impl.control_services.session
    local event = events.Event()
    event.matches = function(e1, e2) return e1 == e2 end
    local ret = pMobSession:ExpectEvent(event, "Handshake")
    local handshakeEvent = events.Event()
    handshakeEvent.matches = function(_, data)
        return data.frameType ~= constants.FRAME_TYPE.CONTROL_FRAME
          and data.serviceType == constants.SERVICE_TYPE.CONTROL
          and data.sessionId == session.sessionId.get()
          and data.rpcType == constants.BINARY_RPC_TYPE.NOTIFICATION
          and data.rpcFunctionId == constants.BINARY_RPC_FUNCTION_ID.HANDSHAKE
      end
    session:ExpectEvent(handshakeEvent, "Handshake internal")
    :Do(function(_, data)
      local binData = data.binaryData
        local dataToSend = session.security:performHandshake(binData)
        if dataToSend then
          local handshakeMessage = {
            frameInfo = 0,
            serviceType = constants.SERVICE_TYPE.CONTROL,
            encryption = false,
            rpcType = constants.BINARY_RPC_TYPE.NOTIFICATION,
            rpcFunctionId = constants.BINARY_RPC_FUNCTION_ID.HANDSHAKE,
            rpcCorrelationId = data.rpcCorrelationId,
            binaryData = dataToSend
          }
          session:Send(handshakeMessage)
        end
      end)
    :Do(function()
        if session.security:isHandshakeFinished() then
          local mobileConnection = self.mobile_session_impl.connection
          event_dispatcher:RaiseEvent(mobileConnection, event)
        end
      end)
    :Times(AnyNumber())
    return ret
  end
end

--[[ @getMobileSession: override original getMobileSession function
-- and add additional functions to the mobile session object
--! @parameters:
--! pAppId - application number (1, 2, etc.)
--! @return: mobile session object
--]]
function actions.getMobileSession(pAppId)
  if not pAppId then pAppId = 1 end
  local session = origGetMobileSession(pAppId)
  if not session.ExpectHandshakeMessage then
    registerExpectServiceEventFunc(session)
    registerStartSecureServiceFunc(session)
  end
  return session
end

return m
