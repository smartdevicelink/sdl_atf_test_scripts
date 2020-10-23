---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0308-protocol-nak-reason.md
--
-- Description: SDL provides reason information in NACK message
-- in case NACK received because of wrong HMI level of mobile application
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered with 'NAVIGATION' HMI type and with 5 protocol
-- 3. Mobile app is in NONE HMI level
--
-- Steps:
-- 1. Mobile app requests the opening of Video/Audio service
-- SDL does:
-- - respond with NACK to StartService request because Video/Audio service can be opened
-- only if app is in FULL or LIMITED HMI levels
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
    reason = { type = common.bsonType.STRING, value = "Service type: 11 disallowed with current HMI level" }
  }
}

local audioServiceParams = {
  reqParams = {
    mtu = { type = common.bsonType.INT64,  value = 131072 }
  },
  nackParams = {
    reason = { type = common.bsonType.STRING, value = "Service type: 10 disallowed with current HMI level" }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppUpdatedProtocolVersion)

common.Title("Test")
common.Step("Start Video Service in wrong HMI level, NACK", common.startServiceUnprotectedNACK,
  { 1, common.serviceType.VIDEO, videoServiceParams.reqParams, videoServiceParams.nackParams })
common.Step("Start Audio Service in wrong HMI level, NACK", common.startServiceUnprotectedNACK,
  { 1, common.serviceType.PCM, audioServiceParams.reqParams, audioServiceParams.nackParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
