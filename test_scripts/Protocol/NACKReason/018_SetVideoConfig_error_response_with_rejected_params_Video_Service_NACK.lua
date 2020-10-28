---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0308-protocol-nak-reason.md
--
-- Description: SDL provides reason information in NACK message in case NACK received because HMI responds with
--  erroneous result code and rejectedParams to Navigation.SetVideoConfig request
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. Mobile app is registered with 'NAVIGATION' HMI type and with 5 protocol
-- 3. Mobile app is activated
--
-- Steps:
-- 1. Mobile app requests the opening of Video service
-- SDL does:
-- - send Navigation.SetVideoConfig request to HMI
-- 2. HMI responds with erroneous result code and rejectedParams to Navigation.SetVideoConfig request
-- SDL does:
-- - respond with NACK to StartService request because HMI responds with erroneous result code
--    to Navigation.SetVideoConfig request
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
    reason = { type = common.bsonType.STRING, value = "Received SetVideoConfig failure response" },
    rejectedParams = {
      type = common.bsonType.ARRAY,
      value = {{ type = common.bsonType.STRING, value = "videoProtocol" }}
    }
  }
}

--[[ Local Functions ]]
local function setVideoConfig()
  common.getHMIConnection():ExpectRequest("Navigation.SetVideoConfig")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "REJECTED", { rejectedParams = { "protocol" }})
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppUpdatedProtocolVersion)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Start Video Service, erroneous SetVideoConfig response with rejectedParams, NACK",
  common.startServiceUnprotectedNACK,
  { 1, common.serviceType.VIDEO, videoServiceParams.reqParams, videoServiceParams.nackParams, setVideoConfig })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
