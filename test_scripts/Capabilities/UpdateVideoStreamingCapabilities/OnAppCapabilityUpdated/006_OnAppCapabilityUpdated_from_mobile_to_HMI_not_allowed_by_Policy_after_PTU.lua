---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0296-Update-video-streaming-capabilities-during-ignition-cycle.md
--
-- Description:
-- Processing OnAppCapabilityUpdated notification from mobile to HMI in case notification is not allowed by policies
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App with `NAVIGATION` appHMIType and 5 transport protocol is registered
-- 3. OnAppCapabilityUpdated notification is allowed by policy for App
--
-- Sequence:
-- 2. PTU is performed with removing of permissions for OnAppCapabilityUpdated notification
-- 2. App sends OnAppCapabilityUpdated for VIDEO_STREAMING capability type
-- SDL does:
-- - a. not send OnAppCapabilityUpdated notification to the HMI
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/UpdateVideoStreamingCapabilities/common')

--[[ Local Variables ]]
local notExpected = 0
local defaultAppCapability = nil

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.functional_groupings["Base-4"].rpcs.OnAppCapabilityUpdated = nil
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App sends OnAppCapabilityUpdated allowed by Policy", common.sendOnAppCapabilityUpdated )

common.Title("Test")
common.Step("Policy Table Update Certificate", common.policyTableUpdate, { ptUpdate })
common.Step("App sends OnAppCapabilityUpdated not allowed by Policy", common.sendOnAppCapabilityUpdated,
	{ defaultAppCapability, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
