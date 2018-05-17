---------------------------------------------------------------------------------------------------
-- Issue:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')
local events = require("events")
local constants = require("protocol_handler/ford_protocol_constants")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

--[[ Local Variables ]]
local testCases = {
  [001] = { t = "PROJECTION", m = true },
  [002] = { t = "NAVIGATION", m = true },
}

--[[ Local Functions ]]
local function appStartAudioStreaming()
  common.getMobileSession():StartService(10)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession():StartStreaming(10,"files/MP3_1140kb.mp3")
          common.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = true })
        end)
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function appStartVideoStreaming()
  common.getMobileSession():StartService(11)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartStream")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession():StartStreaming(11, "files/MP3_4555kb.mp3")
          common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
        end)
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function appStopStreaming()
  common.getMobileSession():StopStreaming("files/MP3_1140kb.mp3")
  common.getMobileSession():StopStreaming("files/MP3_4555kb.mp3")
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function expectEndService(pServiceId)
  local event = events.Event()
  event.matches = function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME
    and data.serviceType == pServiceId
    and data.sessionId == common.getMobileSession().mobile_session_impl.control_services.session.sessionId.get()
    and data.frameInfo == constants.FRAME_INFO.END_SERVICE
  end
  return common.getMobileSession():ExpectEvent(event, "EndService")
end

local function changeAudioSource()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "AUDIO_SOURCE",
    isActive = true })
  common.getMobileSession():ExpectNotification("OnHMIStatus", {
    hmiLevel = "BACKGROUND",
    systemContext = "MAIN",
    audioStreamingState = "NOT_AUDIBLE",
    videoStreamingState = "NOT_STREAMABLE"
  })
  common.wait(2000)
  common.getHMIConnection():SendNotification("Navigation.OnAudioDataStreaming", { available = false })
  common.getHMIConnection():SendNotification("Navigation.OnVideoDataStreaming", { available = false })
  common.getHMIConnection():SendNotification("Navigation.StopAudioStream", { appID = common.getHMIAppId() })
  common.getHMIConnection():SendNotification("Navigation.StopStream", { appID = common.getHMIAppId() })
  expectEndService(10)
  expectEndService(11)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App Config", common.setAppConfig, { 1, tc.t, tc.m })
  runner.Step("Register App", common.registerApp, { 1 })
  runner.Step("Activate App", common.activateApp, { 1 })
  runner.Step("App starts Audio streaming", appStartAudioStreaming)
  runner.Step("App starts Video streaming", appStartVideoStreaming)
  runner.Step("Change Audio Source", changeAudioSource)
  runner.Step("Stop A/V streaming", appStopStreaming)
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
