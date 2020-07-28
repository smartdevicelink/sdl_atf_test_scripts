-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL applies the videoStreamingCapability with additionalVideoStreamingCapabilities parameter
--  with several missed not mandatory parameters in array items received from HMI in UI.GetCapabilities response
--
-- Preconditions:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. SDL requests UI.GetCapabilities()
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) response with additionalVideoStreamingCapabilities
--  with several missed not mandatory parameters in array items
-- SDL does:
-- - a. apply the videoStreamingCapability with additionalVideoStreamingCapabilities internally
-- 3. App registers with 5 transport protocol
-- 4. App requests GetSystemCapability(VIDEO_STREAMING)
-- SDL does:
-- - a. send GetSystemCapability response with videoStreamingCapability that contains
--    the additionalVideoStreamingCapabilities received from HMI in UI.GetCapabilities response
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local isSubscribe = false
local anotherVSC = 2

local vsc = common.getVscData(anotherVSC)
vsc.additionalVideoStreamingCapabilities = {
  {
    preferredResolution = { resolutionWidth = 200, resolutionHeight = 200 },
    supportedFormats = {{ protocol = "WEBM", codec = "H265" }},
    diagonalScreenSize = 200,
    pixelPerInch = 200,
    scale = 3
  },
  {
    preferredResolution = { resolutionWidth = 320, resolutionHeight = 240 },
    scale = 4
  },
  {
    preferredResolution = { resolutionWidth = 640, resolutionHeight = 480 },
    scale = 2
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setVideoStreamingCapabilities, { vsc })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability,
  { isSubscribe, appSessionId, vsc })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
