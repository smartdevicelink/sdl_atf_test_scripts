-- User story: https://github.com/smartdevicelink/sdl_core/issues/1896
--
-- Steps to reproduce:
-- 1. "HeartBeat" param in .ini file is zero
-- 2. SDL, HMI are running
-- 3. App is registered and activated.
-- SDL must:
-- 1. respond ACK to HeartBeat_request from mobile app
-- 2. NOT send HeartBeat_request to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local constants = require('protocol_handler/ford_protocol_constants')
local events = require('events')

--[[ Test Configuration ]]
config.defaultProtocolVersion = 3
runner.testSettings.isSelfIncluded = false

--[[ General Precondition before ATF start ]]
local function BackUpIniFileAndSetHBValue()
  commonPreconditions:BackupFile("smartDeviceLink.ini")
  commonFunctions:write_parameter_to_smart_device_link_ini("HeartBeatTimeout", 0)
end

--[[ Local Functions ]]
local mobSessionConfig = {
  activateHeartbeat = false,
  sendHeartbeatToSDL = false,
  answerHeartbeatFromSDL = true,
  ignoreSDLHeartBeatACK = true
}

local function registerApp(pMobSessionConfig)
  local session = common.mobile.createSession(1, 1, pMobSessionConfig)
  session:StartService(7)
  :Do(function()
    local corId = session:SendRPC("RegisterAppInterface", common.app.getParams(1))
    common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
      { application = { appName = common.app.getParams(1).appName } })
    :Do(function(_, d1)
      common.app.setHMIId(d1.params.application.appID, 1)
    end)
    session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      session:ExpectNotification("OnHMIStatus",
        { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      session:ExpectNotification("OnPermissionsChange")
      :Times(AnyNumber())
    end)
  end)
end

local function WithoutHBFromSDLMsg(pSession)
  local event = events.Event()
  event.matches =
  function(_, data)
    return data.frameType == 0 and
    data.serviceType == 0 and
    data.sessionId == 1 and
    data.frameInfo == 0
  end
  return pSession:ExpectEvent(event, "HB"):Times(0)
end

local function HBACKFromSDLMsg(pSession)
  local event = events.Event()
  event.matches =
  function(_, data)
    return data.frameType == 0 and
    data.serviceType == 0 and
    data.sessionId == 1 and
    data.frameInfo == 255
  end
  return pSession:ExpectEvent(event, "HBACK")
end

local function sendHBFromMobileAndNotReceivingFromSDL()
  local session = common.getMobileSession(1)
  -- Send HB from mobile app to SDL
    session:Send({
      frameType = constants.FRAME_TYPE.CONTROL_FRAME,
      serviceType = constants.SERVICE_TYPE.CONTROL,
      frameInfo = constants.FRAME_INFO.HEARTBEAT
    })
  -- Expect HB from SDL on mobile app
  WithoutHBFromSDLMsg(session)
  -- Expect HB ACK from SDL on mobile app
  HBACKFromSDLMsg(session)
end

local function RestoreIniFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("BackUpIniFileAndSetHBValue is zero", BackUpIniFileAndSetHBValue)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App is registered", registerApp, { mobSessionConfig })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SendHBFromMobileAndNotExpectationHBFromSDL", sendHBFromMobileAndNotReceivingFromSDL)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("RestoreIniFile", RestoreIniFile)
