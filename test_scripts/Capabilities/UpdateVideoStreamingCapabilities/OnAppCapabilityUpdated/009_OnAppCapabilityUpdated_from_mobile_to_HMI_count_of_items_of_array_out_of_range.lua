---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description:
-- Processing OnAppCapabilityUpdated notification with 101 or 0 items
--  in additionalVideoStreamingCapabilities array (out of range) from mobile to HMI in case
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App with NAVIGATION appHMIType is registered
-- 3. OnAppCapabilityUpdated notification is allowed by policy for App
--
-- Sequence:
-- 1. App sends OnAppCapabilityUpdated for VIDEO_STREAMING capability type with 101 or 0 items in
--  additionalVideoStreamingCapabilities array (out of range)
-- SDL does:
-- - a. not send OnAppCapabilityUpdated notification to the HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local notExpected = 0

local cases = {
  outOfLowerBound = {
    appCapability = {
      appCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = { additionalVideoStreamingCapabilities = { }}
    }
  },
  outOfUpperBound = {
    appCapability = {
      appCapabilityType = "VIDEO_STREAMING",
      videoStreamingCapability = common.buildVideoStreamingCapabilities(101)
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for caseName, value in common.spairs(cases) do
  common.Step("OnAppCapabilityUpdated with additionalVideoStreamingCapabilities " ..caseName,
    common.sendOnAppCapabilityUpdated, { value, notExpected })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
