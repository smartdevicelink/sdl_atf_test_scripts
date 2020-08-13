---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Resolution switching from mobile app after receiving OnSystemCapabilityUpdated notification
--  with new video capabilities
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. App is registered and activated with 5 transport protocol
-- 3. HMI sends UI.GetCapabilities(videoStreamingCapability) with additionalVideoStreamingCapabilities
-- 4. App is subscribed to video streaming capabilities update
-- 5. App sent supported video capabilities using OnAppCapabilityUpdated notification to HMI
-- 6. Video service is started
-- 7. App starts video streaming
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated with new video capabilities
-- SDL does:
--  a. send OnSystemCapabilityUpdated notification to App with received parameters
-- 2. App stops streaming and video service by sending EndService(VIDEO) to SDL
-- SDL does:
--  a. send Navi.OnVideoDataStreaming(available=false) to HMI
--  b. respond with EndServiceACK(VIDEO) to Mobile App
--  c. request Navi.StopStream
-- 3. App restarts video service with new video parameters and sends StartService(VIDEO, new_video_params) to SDL
-- SDL does:
--  a. request Navi.SetVideoConfig(new_video_params)
-- 4. HMI responds with SUCCESS resultCode to Navi.SetVideoConfig(new_video_params)
-- SDL does:
--  a. send StartService(VIDEO, new_video_params) to App
-- 5. App starts streaming with new video params
-- SDL does:
--  a. request Navi.StopStream
--  b. send Navi.OnVideoDataStreaming(available=false) to HMI after successful response to Navi.StopStream from HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Variables ]]
local isSubscribed = true
local expected = 1
local appSessionId = 1
local anotherVSC = 2
local isSecure = false

local videoCapSupportedByApp = {
  appCapability = {
    appCapabilityType = "VIDEO_STREAMING",
    videoStreamingCapability = common.buildVideoStreamingCapabilities(3)
  }
}

local videoCapSupportedByHMI = common.buildVideoStreamingCapabilities(5)

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setVideoStreamingCapabilities, { videoCapSupportedByHMI })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability,
  { isSubscribed, appSessionId, videoCapSupportedByHMI })
common.Step("OnAppCapabilityUpdated with supported video capabilities", common.sendOnAppCapabilityUpdated,
  { videoCapSupportedByApp })
common.Step("Start video service", common.startVideoService, { common.getVscData() })
common.Step("Start video streaming", common.startVideoStreaming, { isSecure })

common.Title("Test")
common.Step("OnSystemCapabilityUpdated with new video params", common.sendOnSystemCapabilityUpdated,
  { appSessionId, expected, common.getVscData(anotherVSC) })
common.Step("Stop video streaming", common.stopVideoStreaming)
common.Step("Stop video service", common.stopVideoService)
common.Step("Start video service with new parameters", common.startVideoService, { common.getVscData(anotherVSC) })
common.Step("Start video streaming with new parameters", common.startVideoStreaming, { isSecure })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
