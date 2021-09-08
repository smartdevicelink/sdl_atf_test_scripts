---------------------------------------------------------------------------------------------------
-- Case: Trigger SendInternalError with INVALID_QUERY_ID by establising a secure audio service, 
--       then attempting to send an encrypted RPC
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Security/SecurityQueryErrorHandling/common")
local constants = require("protocol_handler/ford_protocol_constants")
local securityConstants = require('security/security_constants')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Functions ]]
local function startHandshake()
  local serviceId = 10
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = constants.FRAME_INFO.START_SERVICE_ACK,
    encryption = true
  })

  common.getMobileSession():ExpectHandshakeMessage()
  :Times(1)
end

local function sendEncryptedRequest()
  local params = {
    cmdID = 1,
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local cid = common.getMobileSession().mobile_session_impl.rpc_services:SendRPC("AddCommand", params, nil, securityConstants.ENCRYPTION.ON)
  common.getHMIConnection():ExpectRequest("UI.AddCommand", params):Times(0)
  common.getMobileSession():ExpectNotification("OnHashChange"):Times(0)

  local expParams = {
    frameInfo = 0,
    encryption = false,
    rpcType = constants.BINARY_RPC_TYPE.NOTIFICATION,
    rpcFunctionId = constants.BINARY_RPC_FUNCTION_ID.INTERNAL_ERROR,
    payload = {
      id = constants.QUERY_ERROR_CODE.SERVICE_NOT_PROTECTED
    },
    binaryData = string.char(constants.QUERY_ERROR_CODE.SERVICE_NOT_PROTECTED)
  }

  common.expectSecurityQuery(expParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Send handshake for audio service", startHandshake)
runner.Step("Send encrypted request for unprotected service", sendEncryptedRequest)

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
