---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description:
-- Processing OnAppCapabilityUpdated notification with recursive nesting additionalVideoStreamingCapabilities parameter
--  from mobile to HMI
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App with `NAVIGATION` appHMIType and 5 transport protocol is registered
-- 3. OnAppCapabilityUpdated notification is allowed by policy for App
--
-- Sequence:
-- 1. App sends OnAppCapabilityUpdated for VIDEO_STREAMING capability type with additionalVideoStreamingCapabilities
--  parameter that has a nesting additionalVideoStreamingCapabilities parameter
-- SDL does:
-- - a. send OnAppCapabilityUpdated notification to the HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appCapability = {
  appCapability = {
    appCapabilityType = "VIDEO_STREAMING",
    videoStreamingCapability = {
      additionalVideoStreamingCapabilities = {
        common.buildVideoStreamingCapabilities()
      }
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
common.Step("App sends OnAppCapabilityUpdated additionalVideoStreamingCapabilities has a nesting level ",
  common.sendOnAppCapabilityUpdated, { appCapability })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
