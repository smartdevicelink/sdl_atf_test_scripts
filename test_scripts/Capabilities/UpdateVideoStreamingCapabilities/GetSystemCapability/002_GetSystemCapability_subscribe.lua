-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL successfully subscribes an application on OnSystemCapabilityUpdated notification
--  with VIDEO_STREAMING capability type
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. SDL received videoStreamingCapabilities from HMI
-- 3. App is registered and activated
--
-- Sequence:
-- 1. App requests subscription on OnSystemCapabilityUpdated notification with VIDEO_STREAMING capability type
-- SDL does:
-- - a. subscribe App on the notification
-- - b. send response to the App with videoStreamingCapabilities with additionalVideoStreamingCapabilities
--    stored internally
-- 2. HMI sends OnSystemCapabilityUpdated notification with updates of VIDEO_STREAMING capability type for App
-- SDL does:
-- - a. resend OnSystemCapabilityUpdated notification with updates of VIDEO_STREAMING capability type to the App
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local expected = 1
local isSubscribe = true

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setVideoStreamingCapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Subscribe App on VIDEO_STREAMING updates", common.getSystemCapability, { isSubscribe })
common.Step("OnSystemCapabilityUpdated to check subscription",
  common.sendOnSystemCapabilityUpdated, { appSessionId, expected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
