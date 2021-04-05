-- User story: https://github.com/smartdevicelink/sdl_core/issues/1896
--
-- Steps to reproduce:
-- 1. "HeartBeat" param in .ini file is zero
-- 2. SDL, HMI are running
-- 3. App is registered.
-- SDL must:
-- 1. respond ACK to HeartBeat_request from mobile app
-- 2. NOT send HeartBeat_request to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local constants = require('protocol_handler/ford_protocol_constants')
local events = require('events')

--[[ Test Configuration ]]
config.defaultProtocolVersion = 3
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appSessionId = 1

local mobSessionConfig = {
  activateHeartbeat = false,
  sendHeartbeatToSDL = false,
  answerHeartbeatFromSDL = false,
  ignoreSDLHeartBeatACK = false
}

--[[ Local Functions ]]
local function registerApp(pMobSessionConfig)
  local mobConnId = 1
  local session = common.mobile.createSession(appSessionId, mobConnId, pMobSessionConfig)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", common.app.getParams(appSessionId))
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.app.getParams(appSessionId).appName } })
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    end)
end

local function WithoutHBFromSDLMsg(pSession)
  local event = events.Event()
  event.matches = function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME
      and data.serviceType == constants.SERVICE_TYPE.CONTROL
      and data.sessionId == common.getMobileSession(appSessionId).sessionId
      and data.frameInfo == constants.FRAME_INFO.HEARTBEAT
  end
  return pSession:ExpectEvent(event, "HB"):Times(0)
end

local function HBACKFromSDLMsg(pSession)
  local event = events.Event()
  event.matches = function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME
      and data.serviceType == constants.SERVICE_TYPE.CONTROL
      and data.sessionId == common.getMobileSession(appSessionId).sessionId
      and data.frameInfo == constants.FRAME_INFO.HEARTBEAT_ACK
  end
  return pSession:ExpectEvent(event, "HBACK")
end

local function sendHBFromMobile()
  local session = common.getMobileSession(appSessionId)
  -- Send HB from mobile app to SDL
  session:Send({
    frameType = constants.FRAME_TYPE.CONTROL_FRAME,
    serviceType = constants.SERVICE_TYPE.CONTROL,
    frameInfo = constants.FRAME_INFO.HEARTBEAT
  })
  -- Not expect HB from SDL on mobile app
  WithoutHBFromSDLMsg(session)
  -- Expect HB ACK from SDL on mobile app
  HBACKFromSDLMsg(session)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set HeartBeatTimeout=0 in ini file", common.setSDLIniParameter, { "HeartBeatTimeout", 0 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App is registered", registerApp, { mobSessionConfig })

runner.Title("Test")
runner.Step("SDL responds with ACK to HB request and does not request HB to mobile app", sendHBFromMobile)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
