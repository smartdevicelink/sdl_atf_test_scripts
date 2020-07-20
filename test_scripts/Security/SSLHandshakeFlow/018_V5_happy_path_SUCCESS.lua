---------------------------------------------------------------------------------------------------
-- Issues: https://github.com/smartdevicelink/sdl_core/issues/2142
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Security/SSLHandshakeFlow/common")
local constants = require("protocol_handler/ford_protocol_constants")
local utils = require("user_modules/utils")
local bson

if utils.isFileExist("lib/bson4lua.so") then
  bson = require('bson4lua')
else
  runner.skipTest("'bson4lua' library is not available in ATF")
end

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 5
constants.FRAME_SIZE.P5 = 131084

--[[ Local Variables ]]
local bsonType = {
  DOUBLE   = 0x01,
  STRING   = 0x02,
  DOCUMENT = 0x03,
  ARRAY    = 0x04,
  BOOLEAN  = 0x08,
  INT32    = 0x10,
  INT64    = 0x12
}

--[[ Local Functions ]]
local function startServiceProtectedACK(pServiceId, pRequestPayload, pResponsePayload)
  common.getMobileSession():StartSecureService(pServiceId, bson.to_bytes(pRequestPayload))
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
  :ValidIf(function(_, data)
      local actPayload = bson.to_table(data.binaryData)
      utils.printTable(actPayload)
      return compareValues(pResponsePayload, actPayload, "binaryData")
    end)
  if pServiceId == 7 then
    common.getMobileSession():ExpectHandshakeMessage()
  elseif pServiceId == 11 then
    common.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig")
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Switch RPC Service to Protected mode ACK", startServiceProtectedACK, {
  constants.SERVICE_TYPE.RPC,
  {
    protocolVersion = { type = bsonType.STRING, value = "5.0.0" }
  },
  {
    hashId          = { type = bsonType.INT32,  value = 0 },
    mtu             = { type = bsonType.INT64,  value = 131072 },
    protocolVersion = { type = bsonType.STRING, value = "5.0.0" }
  }
})
runner.Step("Start Audio Service in Protected mode ACK", startServiceProtectedACK, {
  constants.SERVICE_TYPE.PCM,
  {
  },
  {
    mtu             = { type = bsonType.INT64,  value = 131072 }
  }
})
runner.Step("Start Video Service in Protected mode ACK", startServiceProtectedACK, {
  constants.SERVICE_TYPE.VIDEO,
  {
    height          = { type = bsonType.INT32,  value = 350 },
    width           = { type = bsonType.INT32,  value = 800 },
    videoProtocol   = { type = bsonType.STRING, value = "RAW" },
    videoCodec      = { type = bsonType.STRING, value = "H264" },
  },
  {
    mtu             = { type = bsonType.INT64,  value = 131072 },
    height          = { type = bsonType.INT32,  value = 350 },
    width           = { type = bsonType.INT32,  value = 800 },
    videoProtocol   = { type = bsonType.STRING, value = "RAW" },
    videoCodec      = { type = bsonType.STRING, value = "H264" },
  }
})

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
