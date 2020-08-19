---------------------------------------------------------------------------------------------------
--  Precondition:
--  1) Initialize the client side certifcate file for SDL
--  2) Start SDL, HMI, connect Mobile device
--  3) Register App_1 on SDL.
--
--  Steps:
--  1) Send StartService Request(with protocol version 5.3.0) to switch the RPC Service to Protected mode
--  SDL Does:
--    a) Send a StartService ACK message
--  2) Send a StartService Request to start a protected VIDEO service
--  SDL Does:
--    a) Send a StartService ACK message
--  3) Send another StartService Request to start a second protected VIDEO service
--  SDL Does:
--    a) Send a StartService NACK message with a reason parameter in the bson payload
--  4) Unregister and re-register App_1
--  5) Send StartService Request(with protocol version 5.2.0) to switch the RPC Service to Protected mode
--  SDL Does:
--    a) Send a StartService ACK message
--  6) Send a StartService Request to start a protected VIDEO service
--  SDL Does:
--    a) Send a StartService ACK message
--  7) Send another StartService Request to start a second protected VIDEO service
--  SDL Does:
--    a) Send a StartService NACK message with an empty bson payload(no reason param)
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
    ackParams = {
      hashId          = { type = common.bsonType.INT32,  value = 0 },
      mtu             = { type = common.bsonType.INT64,  value = 131072 },
      protocolVersion = { type = common.bsonType.STRING, value = "5.3.0" }    
    }
  }
}
rpcServiceParams[2] = utils.cloneTable(rpcServiceParams[1])
rpcServiceParams[2].reqParams.protocolVersion.value = "5.2.0"
rpcServiceParams[2].ackParams.protocolVersion.value = "5.2.0"

videoServiceParams = {
  [1] = {
    reqParams = {
      height          = { type = common.bsonType.INT32,  value = 350 },
      width           = { type = common.bsonType.INT32,  value = 800 },
      videoProtocol   = { type = common.bsonType.STRING, value = "RAW" },
      videoCodec      = { type = common.bsonType.STRING, value = "H264" },    
    },
    ackParams = {
      mtu             = { type = common.bsonType.INT64,  value = 131072 },
      height          = { type = common.bsonType.INT32,  value = 350 },
      width           = { type = common.bsonType.INT32,  value = 800 },
      videoProtocol   = { type = common.bsonType.STRING, value = "RAW" },
      videoCodec      = { type = common.bsonType.STRING, value = "H264" },    
    },
    nackParams = {
      reason = { type = common.bsonType.STRING, value = "Session observer refused to create service of type "..common.serviceType.VIDEO}
    }
  }
}
videoServiceParams[2] = utils.cloneTable(videoServiceParams[1])
videoServiceParams[2].nackParams = {}

--[[ Local Functions ]]

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" , true})
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp, {1})

runner.Title("Test NAK reason param(protocol version 5.3.0)")

runner.Step("Activate App", common.activateApp, {1})
runner.Step("Switch RPC Service to Protected mode ACK", common.startServiceProtectedACK, {1, common.serviceType.RPC, rpcServiceParams[1].reqParams, rpcServiceParams[1].ackParams})
runner.Step("Start Video Service in Protected mode ACK", common.startServiceProtectedACK, {1, common.serviceType.VIDEO, videoServiceParams[1].reqParams, videoServiceParams[1].ackParams})
runner.Step("Start Second Video Service in Protected mode NACK", common.startServiceProtectedNACK, {1, common.serviceType.VIDEO, videoServiceParams[1].reqParams, videoServiceParams[1].nackParams})
runner.Step("Unregister App 1", common.app.unRegister, {1})

runner.Title("Test NAK reason param(protocol version 5.2.0)")

runner.Step("Register App", common.registerApp, {1})
runner.Step("Activate App", common.activateApp, {1})
runner.Step("Switch RPC Service to Protected mode ACK", common.startServiceProtectedACK, {1, common.serviceType.RPC, rpcServiceParams[2].reqParams, rpcServiceParams[2].ackParams})
runner.Step("Start Video Service in Protected mode ACK", common.startServiceProtectedACK, {1, common.serviceType.VIDEO, videoServiceParams[2].reqParams, videoServiceParams[2].ackParams})
runner.Step("Start Second Video Service in Protected mode NACK", common.startServiceProtectedNACK, {1, common.serviceType.VIDEO, videoServiceParams[2].reqParams, videoServiceParams[2].nackParams})

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
