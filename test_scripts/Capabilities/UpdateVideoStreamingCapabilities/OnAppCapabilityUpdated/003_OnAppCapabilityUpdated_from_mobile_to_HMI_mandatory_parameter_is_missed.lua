---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description:
-- Processing OnAppCapabilityUpdated notification without mandatory parameter from mobile to HMI
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App with `NAVIGATION` appHMIType and 5 transport protocol is registered
-- 3. OnAppCapabilityUpdated notification is allowed by policy for App
--
-- Sequence:
-- 1. App sends OnAppCapabilityUpdated without mandatory parameter appCapabilityType
-- SDL does:
-- - a. not send OnAppCapabilityUpdated notification to the HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local notExpected = 0

local appCapability = {
  appCapability = {
    -- appCapabilityType - mandatory parameter is missed
    videoStreamingCapability = common.buildVideoStreamingCapabilities()
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends OnAppCapabilityUpdated without mandatory parameter appCapabilityType",
	common.sendOnAppCapabilityUpdated, { appCapability, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
