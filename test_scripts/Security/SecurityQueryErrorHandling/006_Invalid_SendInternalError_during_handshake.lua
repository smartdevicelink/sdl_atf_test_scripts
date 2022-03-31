---------------------------------------------------------------------------------------------------
-- Case: Send SendInternalError query with invalid/unknown error code when establishing a secure
--       audio service, verify Core handles the message internally and that it does not interrupt
--       the handshake process
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Security/SecurityQueryErrorHandling/common")
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local constants = require("protocol_handler/ford_protocol_constants")
local securityConstants = require('security/security_constants')
local json = require("json")

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

  local params = {
    frameInfo = 0,
    serviceType = constants.SERVICE_TYPE.CONTROL,
    encryption = false,
    rpcType = constants.BINARY_RPC_TYPE.NOTIFICATION,
    rpcFunctionId = constants.BINARY_RPC_FUNCTION_ID.INTERNAL_ERROR,
    payload = json.encode({
      id = 0xDE, -- Unknown error code
      text = "Something went wrong"
    }),
    binaryData = string.char(0xDE)
  }

  common.getMobileSession():ExpectHandshakeMessage()
  :Do(function(_, data)
      common.sendSecurityQuery(params)
    end)
  :Times(1)
  commonTestCases:DelayedExp(5000)
end

local function checkCrashed()
  if not common.sdl.isRunning() then common.run.fail("SDL crashed") end
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
runner.Step("Check SDL Core status", checkCrashed)

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
