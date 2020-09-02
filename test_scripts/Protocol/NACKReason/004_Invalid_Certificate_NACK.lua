---------------------------------------------------------------------------------------------------
--  Precondition:
--  1) Initialize the client side certifcate file for SDL using an expired certificate
--  2) Start SDL, HMI, connect Mobile device
--  3) Register App_1 and App_2 on SDL.
--
--  Steps:
--  1) Trigger a PTU clearing the certifcate field in the module config
--  SDL Does:
--    a) Clear the module_config.certificate field in the policy table
--  2) Send StartService Request(with protocol version 5.3.0) from App 1 to switch the RPC Service to Protected mode
--  SDL Does:
--    a) Send a StartService NAK message with a reason parameter in the bson payload
--  3) Trigger a PTU setting the certificate field in the module config to an expired certificate
--  SDL Does:
--    a) Set the module_config.certificate in the policy table
--  4) Send StartService Request(with protocol version 5.3.0) from App 1 to switch the RPC Service to Protected mode
--  SDL Does:
--    a) Send a StartService NAK message with a reason parameter in the bson payload
--  5) Trigger a PTU clearing the certifcate field in the module config
--  SDL Does:
--    a) Clear the module_config.certificate field in the policy table
--  6) Send StartService Request(with protocol version 5.2.0) from App 2 to switch the RPC Service to Protected mode
--  SDL Does:
--    a) Send a StartService NAK message with an empty bson payload(no reason param)
--  7) Trigger a PTU setting the certificate field in the module config to an expired certificate
--  SDL Does:
--    a) Set the module_config.certificate in the module config
--  8) Send StartService Request(with protocol version 5.2.0) from App 2 to switch the RPC Service to Protected mode
--  SDL Does:
--    a) Send a StartService NAK message with an empty bson payload(no reason param)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
if not utils.isFileExist("lib/bson4lua.so") then
  runner.skipTest("'bson4lua' library is not available in ATF")
  runner.Step("Skipping test")
  return
end

local common = require("test_scripts/Protocol/commonProtocol")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 5

--[[ Local Variables ]]
rpcServiceParams = {
  [1] = {
    reqParams = {
      protocolVersion = { type = common.bsonType.STRING, value = "5.3.0" }
    },
    nackParams = {
      reason = { type = common.bsonType.STRING, value = "Invalid certificate: Certificate already expired" }
    }
  }
}
rpcServiceParams[2] = utils.cloneTable(rpcServiceParams[1])
rpcServiceParams[2].reqParams.protocolVersion.value = "5.2.0"
rpcServiceParams[2].nackParams = {}

--[[ Local Functions ]]

local function missingCertificateNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
  common.startServiceProtectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
  common.getMobileSession():ExpectHandshakeMessage()
  :Times(0)
  local function ptUpdate(pTbl)
    pTbl.policy_table.module_config.certificate = nil
  end
  common.policyTableUpdateSuccess(ptUpdate)
end

local function expiredCertificateNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
  common.startServiceProtectedNACK(pAppId, pServiceId, pRequestPayload, pResponsePayload)
  common.getMobileSession():ExpectHandshakeMessage()
  :Times(0)
  local function ptUpdate(pTbl)
    local filePath = "./files/Security/client_credential_expired.pem"
    local crt = common.readFile(filePath)
    pTbl.policy_table.module_config.certificate = crt
  end
  common.policyTableUpdateSuccess(ptUpdate)
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential_expired.pem"})
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App 1", common.registerAppWOPTU, {1})
runner.Step("Register App 2", common.registerApp, {2})

runner.Title("Test NAK reason param(protocol version 5.3.0)")
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("Switch RPC Service to Protected mode NACK (Missing certificate)", missingCertificateNACK, {1, common.serviceType.RPC, rpcServiceParams[1].reqParams, rpcServiceParams[1].nackParams})
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("Switch RPC Service to Protected mode NACK(Expired certificate)", expiredCertificateNACK, {1, common.serviceType.RPC, rpcServiceParams[1].reqParams, rpcServiceParams[1].nackParams})

runner.Title("Test NAK reason param(protocol version 5.2.0)")

runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("Switch RPC Service to Protected mode NACK (Missing certificate)", missingCertificateNACK, {2, common.serviceType.RPC, rpcServiceParams[2].reqParams, rpcServiceParams[2].nackParams})
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("Switch RPC Service to Protected mode NACK(Expired certificate)", expiredCertificateNACK, {2, common.serviceType.RPC, rpcServiceParams[2].reqParams, rpcServiceParams[2].nackParams})

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
