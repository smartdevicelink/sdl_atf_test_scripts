---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description:
-- Processing OnAppCapabilityUpdated notification with videoStreamingCapability that doesn't match
--  with the videoStreamingCapability received from HMI on start from mobile to HMI
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App with `PROJECTION` appHMIType and 5 protocol version is registered
-- 3. OnAppCapabilityUpdated notification is allowed by policy for App
--
-- Sequence:
-- 1. App sends OnAppCapabilityUpdated for VIDEO_STREAMING capability type with videoStreamingCapability that doesn't
--  match with the videoStreamingCapability received from HMI on start
-- SDL does:
-- - a. send OnAppCapabilityUpdated notification to the HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local isSubscribe = false
local appCapability = {
  appCapability = {
    appCapabilityType = "VIDEO_STREAMING",
    videoStreamingCapability = common.buildVideoStreamingCapabilities()
  }
}
local vsc = common.getDefaultHMITable().UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
  common.Step("GetSystemCapability with default videoStreamingCapability", common.getSystemCapability,
    { isSubscribe, appSessionId, vsc })

common.Title("Test")
common.Step("App sends OnAppCapabilityUpdated with new videoStreamingCapability", common.sendOnAppCapabilityUpdated,
	{ appCapability })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
