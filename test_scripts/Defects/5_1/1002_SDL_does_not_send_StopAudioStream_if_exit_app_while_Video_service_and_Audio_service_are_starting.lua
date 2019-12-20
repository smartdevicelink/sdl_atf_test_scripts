---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1002
-- Description: SDL does not send StopAudioStream() if exit app while Video service and Audio service are starting
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) There is a mobile app which is audio/video source
-- In case:
-- 1) App starts Audio/Video streaming
-- 2) User press Exit App on menu app
-- Expected result:
-- 1) SDL must send:
-- Navigation.OnAudioDataStreaming(available = false)
-- Navigation.OnVideoDataStreaming(available = false)
-- Navigation.StopAudioStream
-- Navigation.StopStream
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/TTSChunks/common')
local events = require("events")
local constants = require("protocol_handler/ford_protocol_constants")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Functions ]]
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

local function exitAppOnMenuApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
  { appID = common.app.getHMIId(), reason = "USER_EXIT" })
  common.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = false }):Times(AtLeast(1))
  common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false }):Times(AtLeast(1))
  common.getHMIConnection():ExpectRequest("Navigation.StopAudioStream", { appID = common.getHMIAppId() })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getHMIConnection():ExpectRequest("Navigation.StopStream", { appID = common.getHMIAppId() })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  expectEndService(10)
  expectEndService(11)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("App starts Video streaming", appStartVideoStreaming)
runner.Step("App starts Audio streaming", appStartAudioStreaming)
runner.Step("App exit from menu app", exitAppOnMenuApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
