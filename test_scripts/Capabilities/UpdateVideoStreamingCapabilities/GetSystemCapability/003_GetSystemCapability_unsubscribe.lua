-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: SDL successfully unsubscribes an application from OnSystemCapabilityUpdated notification
--  with VIDEO_STREAMING capability type
--
-- Preconditions:
-- 1. SDL and HMI are started
-- 2. SDL received videoStreamingCapabilities from HMI
-- 3. App is registered and activated
-- 4. App is subscribed on OnSystemCapabilityUpdated notification with VIDEO_STREAMING capability type
--
-- Sequence:
-- 1. App requests unsubscription from OnSystemCapabilityUpdated notification
--  with VIDEO_STREAMING capability type
-- SDL does:
-- - a. unsubscribe App from the notification
-- - b. send response to the App with videoStreamingCapabilities with additionalVideoStreamingCapabilities
--    stored internally
-- 2. HMI sends OnSystemCapabilityUpdated notification with updates of VIDEO_STREAMING capability type for App
-- SDL does:
-- - a. not resend OnSystemCapabilityUpdated notification with updates of VIDEO_STREAMING capability type
--    to the App
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local notExpected = 0
local isSubscribe = true
local isUnsubscribe = false

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setVideoStreamingCapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Subscribe App on VIDEO_STREAMING updates", common.getSystemCapability, { isSubscribe })

common.Title("Test")
common.Step("Unsubscribe App from VIDEO_STREAMING updates", common.getSystemCapability, { isUnsubscribe })
common.Step("OnSystemCapabilityUpdated to check unsubscription", common.sendOnSystemCapabilityUpdated,
  { appSessionId, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
