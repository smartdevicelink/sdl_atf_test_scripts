---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1002
--
-- Description: Check that SDL sends StopAudioStream() in case user exit from App while Video service and
--  Audio service are starting
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) Navigation App is registered and activated
-- 3) Video streaming is started
-- 4) Audio streaming is started
-- In case:
-- 1) User Exit from App
-- SDL does:
-- - send Navigation.OnAudioDataStreaming(available = false) notification to HMI
-- - send Navigation.OnVideoDataStreaming(available = false) notification to HMI
-- - send Navigation.StopAudioStream request to HMI
-- - send Navigation.StopStream request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local events = require("events")
local constants = require("protocol_handler/ford_protocol_constants")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local audioServiceId = 10
local videoServiceId = 11

--[[ Local Functions ]]
local function appStartVideoStreaming()
  common.getMobileSession():StartService(videoServiceId)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartStream")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession():StartStreaming(videoServiceId, "files/SampleVideo_5mb.mp4")
          common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
        end)
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function appStartAudioStreaming()
  common.getMobileSession():StartService(audioServiceId)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession():StartStreaming(audioServiceId,"files/MP3_1140kb.mp3")
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

local function endServiceByUserExit()
  common.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = false })
  common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
  common.getHMIConnection():ExpectRequest("Navigation.StopAudioStream", { appID = common.getHMIAppId() })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getHMIConnection():ExpectRequest("Navigation.StopStream", { appID = common.getHMIAppId() })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  expectEndService(audioServiceId)
  expectEndService(videoServiceId)
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
    { appID = common.app.getHMIId(), reason = "USER_EXIT" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("App starts Video streaming", appStartVideoStreaming)
runner.Step("App starts Audio streaming", appStartAudioStreaming)

runner.Title("Test")
runner.Step("EndService by USER_EXIT", endServiceByUserExit)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
