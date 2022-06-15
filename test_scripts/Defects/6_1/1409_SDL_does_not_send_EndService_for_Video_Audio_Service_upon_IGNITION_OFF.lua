-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1409
--
-- Description:EndService from SDL  to mobile app for RPC, Audio and Video services during IGNITION_OFF

-- In case
-- 1) SDL and HMI are started
-- 2) SPT is registered using v3 protocol and activated
-- 3) Video service is started
-- 4) Audio service is started
-- 5) HMI sends IGNITION_OFF to SDL
-- SDL does:
-- 1. send EndService (Control Frame 0x04) for: RPC, Audio and Video services during switching off
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local constants = require("protocol_handler/ford_protocol_constants")
local events = require('events')
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

--[[ Local Variables ]]
local audioServiceId = 10
local videoServiceId = 11

--[[ Local Functions ]]
local function startServiceStreaming(pService)
  local serviceReq
  local serviceNotif
  local streamFile
  if pService == audioServiceId then
    serviceReq = "Navigation.StartAudioStream"
    serviceNotif = "Navigation.OnAudioDataStreaming"
    streamFile = "files/MP3_1140kb.mp3"
  elseif pService == videoServiceId then
    serviceReq = "Navigation.StartStream"
    serviceNotif = "Navigation.OnVideoDataStreaming"
    streamFile = "files/SampleVideo_5mb.mp4"
  end
  common.getMobileSession():StartService(pService)
  :Do(function()
      common.getHMIConnection():ExpectRequest(serviceReq)
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession():StartStreaming(pService,streamFile)
          common.getHMIConnection():ExpectNotification(serviceNotif, { available = true })
        end)
    end)
end

local function ignitionOffwithEndServices()
  common.getHMIConnection():ExpectRequest("Navigation.StopStream")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getHMIConnection():ExpectRequest("Navigation.StopAudioStream")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  local endServiceEvent = events.Event()
  endServiceEvent.matches = function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
      data.frameInfo == constants.FRAME_INFO.END_SERVICE and
      data.sessionId == common.getMobileSession().sessionId and
      (data.serviceType == constants.SERVICE_TYPE.VIDEO or
      data.serviceType == constants.SERVICE_TYPE.PCM or
      data.serviceType == constants.SERVICE_TYPE.RPC)
  end

  common.getMobileSession():ExpectEvent(endServiceEvent, "EndService")
  :Times(3)
  :Do(function(_, data)
      common.getMobileSession():Send({
        frameType   = constants.FRAME_TYPE.CONTROL_FRAME,
        serviceType = data.serviceType,
        frameInfo   = constants.FRAME_INFO.END_SERVICE_ACK,
        sessionId   = common.getMobileSession().sessionId,
      })
    end)

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
  :Do(function()
      SDL.DeleteFile()
    end)

  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("App starts Audio streaming", startServiceStreaming, { audioServiceId })
runner.Step("App starts Video streaming", startServiceStreaming, { videoServiceId })
runner.Step("Ignition off", ignitionOffwithEndServices)
