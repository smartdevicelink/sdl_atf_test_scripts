-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL sends GetSystemCapability response with videoStreamingCapabilities received from HMI on startup
--  to the application after updates of video streaming capabilities for another application
--  via OnSystemCapabilityUpdated notification
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. SDL received videoStreamingCapabilities from HMI
-- 3. App1 is registered and activated
-- 4. App1 is subscribed on OnSystemCapabilityUpdated notification with VIDEO_STREAMING capability type
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated notification with updates of VIDEO_STREAMING capability type for App1
-- SDL does:
-- - a. resend OnSystemCapabilityUpdated notification with updates of VIDEO_STREAMING capability type
--    to the App1
-- 2. App2 is registered and requests videoStreamingCapabilities via GetSystemCapability RPC
-- SDL does:
-- - a. send response to the App2 with received from HMI on startup videoStreamingCapabilities
--    which stored internally
-- - b. not request videoStreamingCapabilities from HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local expected = 1

local vsc = common.buildVideoStreamingCapabilities(5)
vsc.additionalVideoStreamingCapabilities[1].preferredResolution = { resolutionWidth = 1920, resolutionHeight = 1080 }
vsc.additionalVideoStreamingCapabilities[2].preferredResolution = { resolutionWidth = 1024, resolutionHeight = 768 }
vsc.additionalVideoStreamingCapabilities[5].preferredResolution = { resolutionWidth = 15, resolutionHeight = 2 }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setVideoStreamingCapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App1", common.registerAppWOPTU)
common.Step("Subscribe App1 on VIDEO_STREAMING updates", common.getSystemCapability, { true })

common.Title("Test")
common.Step("OnSystemCapabilityUpdated notification processing", common.sendOnSystemCapabilityUpdated,
  { appSessionId1, expected, vsc })
common.Step("Check GetSystemCapability processing App1", common.getSystemCapabilityExtended, { appSessionId1 })
common.Step("Register App2", common.registerAppWOPTU, { appSessionId2 })
common.Step("Activate App2", common.activateApp, { appSessionId2 })
common.Step("Check GetSystemCapability processing App2", common.getSystemCapabilityExtended, { appSessionId2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
