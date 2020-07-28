-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL applies the videoStreamingCapability with additionalVideoStreamingCapabilities parameter
--  received from HMI in UI.GetCapabilities response
--
-- Preconditions:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. SDL requests UI.GetCapabilities()
-- 2. HMI sends UI.GetCapabilities(videoStreamingCapability) response with additionalVideoStreamingCapabilities
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

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setVideoStreamingCapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("App sends GetSystemCapability for VIDEO_STREAMING", common.getSystemCapability)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
