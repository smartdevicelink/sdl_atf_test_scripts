---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description:
-- Processing OnAppCapabilityUpdated notification from mobile to HMI
--  in case app version is less then notification version
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App with `NAVIGATION` appHMIType, 5 transport protocol, version 6.0 is registered
-- 3. OnAppCapabilityUpdated notification is allowed by policy for App
--
-- Sequence:
-- 1. App sends OnAppCapabilityUpdated for VIDEO_STREAMING capability type
-- SDL does:
-- - a. not send OnAppCapabilityUpdated notification to the HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local notExpected = 0
local defaultAppCapability = nil

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("App sends OnAppCapabilityUpdated for VIDEO_STREAMING", common.sendOnAppCapabilityUpdated,
  { defaultAppCapability, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
