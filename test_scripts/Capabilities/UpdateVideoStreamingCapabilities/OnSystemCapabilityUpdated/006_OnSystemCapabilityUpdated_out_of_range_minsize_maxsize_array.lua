---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description: Processing of OnSystemCapabilityUpdated notification with invalid
--  number of additionalVideoStreamingCapabilities array items
--
-- Preconditions:
-- 1. HMI capabilities contain data about videoStreamingCapability
-- 2. SDL and HMI are started
-- 3. App is registered, activated and subscribed on videoStreamingCapability updates
--
-- Sequence:
-- 1. HMI sends OnSystemCapabilityUpdated notification for "VIDEO_STREAMING" to SDL with invalid
--  number of additionalVideoStreamingCapabilities array items
-- SDL does:
--  a. not send OnSystemCapabilityUpdated (videoStreamingCapability) notification to mobile
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local notExpected = 0
local isSubscribe = true

local arraySize = {
  minSize = 0,
  maxSize = 101
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Set HMI Capabilities", common.setVideoStreamingCapabilities)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("Subscribe App on VIDEO_STREAMING updates", common.getSystemCapability, { isSubscribe })

common.Title("Test")
for parameter, value in pairs(arraySize) do
  common.Step("Check OnSystemCapabilityUpdated notification processing out of range " .. parameter .. " " .. value,
    common.sendOnSystemCapabilityUpdated, { appSessionId, notExpected, common.buildVideoStreamingCapabilities(value) })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
