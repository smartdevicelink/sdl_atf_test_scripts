---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0308-protocol-nak-reason.md
--
-- Description: SDL provides reason information in NACK message
-- in case NACK received because of force unprotected settings for Video and Audio services
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered with 'NAVIGATION' HMI type and with 5 protocol
-- 3. Mobile app is activated
--
-- Steps:
-- 1. Mobile app requests the opening of protected Video/Audio service
-- SDL does:
-- - respond with NACK to StartService request because protected service is requested
-- - provide reason information in NACK message
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local videoServiceParams = {
  reqParams = {
    height        = { type = common.bsonType.INT32,  value = 350 },
    width         = { type = common.bsonType.INT32,  value = 800 },
    videoProtocol = { type = common.bsonType.STRING, value = "RAW" },
    videoCodec    = { type = common.bsonType.STRING, value = "H264" },
  },
  nackParams = {
    reason = {
      type = common.bsonType.STRING,
      value = "Service type: 11 disallowed by settings. Allowed only in unprotected mode"
    }
  }
}

local audioServiceParams = {
  reqParams = {
    mtu = { type = common.bsonType.INT64,  value = 131072 }
  },
  nackParams = {
    reason = {
      type = common.bsonType.STRING,
      value = "Service type: 10 disallowed by settings. Allowed only in unprotected mode"
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem"})
common.Step("ForceUnprotectedService = 0x0A, 0x0B", common.sdl.setSDLIniParameter,
  { "ForceUnprotectedService", "0x0A, 0x0B" })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppUpdatedProtocolVersion)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Start protected Video Service, NACK", common.startServiceProtectedNACK,
  { 1, common.serviceType.VIDEO, videoServiceParams.reqParams, videoServiceParams.nackParams })
common.Step("Start protected Audio Service, NACK", common.startServiceProtectedNACK,
  { 1, common.serviceType.PCM, audioServiceParams.reqParams, audioServiceParams.nackParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
