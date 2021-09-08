---------------------------------------------------------------------------------------------------
-- Case: Trigger SendInternalError with INVALID_QUERY_ID by responding to SendHandshakeData with
--       a correct payload, but an invalid query ID (0x10)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Security/SecurityQueryErrorHandling/common")
local constants = require("protocol_handler/ford_protocol_constants")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Functions ]]
local function startHandshake()
  local serviceId = 7
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = constants.FRAME_INFO.START_SERVICE_ACK,
    encryption = true
  }):Times(0)

  local response = {
    frameInfo = 0,
    serviceType = constants.SERVICE_TYPE.CONTROL,
    encryption = false,
    rpcType = constants.BINARY_RPC_TYPE.RESPONSE,
    rpcFunctionId = 0x10
  }

  local expParams = {
    frameInfo = 0,
    encryption = false,
    rpcType = constants.BINARY_RPC_TYPE.NOTIFICATION,
    rpcFunctionId = constants.BINARY_RPC_FUNCTION_ID.INTERNAL_ERROR,
    payload = {
      id = constants.QUERY_ERROR_CODE.INVALID_QUERY_ID
    },
    binaryData = string.char(constants.QUERY_ERROR_CODE.INVALID_QUERY_ID)
  }

  common.HandshakeMessageError(response, expParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("Send invalid handshake data response", startHandshake)

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
