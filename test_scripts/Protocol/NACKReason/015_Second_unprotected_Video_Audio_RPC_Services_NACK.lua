---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0308-protocol-nak-reason.md
--
-- Description: SDL provides reason information in NACK message
-- in case NACK received because of second opening of unprotected Video and Audio services
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered with 'NAVIGATION' HMI type and with 5 protocol
-- 3. Mobile app is activated
-- 4. Unprotected RPC, Video and Audio services are opened
--
-- Steps:
-- 1. Mobile app requests the opening of unprotected Video/Audio/RPC service
-- SDL does:
-- - respond with NACK to StartService request because unprotected service is opened
-- - provide reason information in NACK message
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local function reasonMessage(pService)
  return "Cannot start an unprotected service of type " .. pService ..
    ". Session 1 already has an unprotected service of type " .. pService
end

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
      value = reasonMessage(common.serviceType.VIDEO)
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
      value =  reasonMessage(common.serviceType.PCM)
    }
  }
}

local rpcServiceParams = {
  reqParams = {
    protocolVersion = { type = common.bsonType.STRING, value = "5.3.0" }
  },
  nackParams = {
    reason = {
      type = common.bsonType.STRING,
      value = reasonMessage(common.serviceType.RPC)
    }
  }
}

--[[ Local Functions ]]
local function setVideoConfig()
  common.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppUpdatedProtocolVersion)
common.Step("Activate App", common.activateApp)
common.Step("Start unprotected Video Service, ACK", common.startServiceUnprotectedACK,
  { 1, common.serviceType.VIDEO, videoServiceParams.reqParams, videoServiceParams.reqParams, setVideoConfig })
common.Step("Start unprotected Audio Service, ACK", common.startServiceUnprotectedACK,
  { 1, common.serviceType.PCM, audioServiceParams.reqParams, audioServiceParams.reqParams })

common.Title("Test")
common.Step("Start unprotected Video Service, NACK", common.startServiceUnprotectedNACK,
  { 1, common.serviceType.VIDEO, videoServiceParams.reqParams, videoServiceParams.nackParams })
common.Step("Start unprotected Audio Service, NACK", common.startServiceUnprotectedNACK,
  { 1, common.serviceType.PCM, audioServiceParams.reqParams, audioServiceParams.nackParams })
common.Step("Start unprotected RPC Service, NACK", common.startServiceUnprotectedNACK,
  { 1, common.serviceType.RPC, rpcServiceParams.reqParams, rpcServiceParams.nackParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
