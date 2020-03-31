---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL deletes "hmi_capabilities_cache.json" file during MASTER_RESET
--
-- Preconditions:
-- 1. hmi_capabilities_cache.json file doesn't exist on file system
-- 2. SDL and HMI are started
-- 3. HMI sends all capability to SDL
-- 4. SDL persists capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- Sequence:
-- 1. HMI sends OnExitAllApplications with reason MASTER_RESET
-- - a. deleted "hmi_capabilities_cache.json" file in AppStorageFolder
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start)
common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)

common.Title("Test")
common.Step("Shutdown by MASTER_RESET", common.masterReset)
common.Step("Check that SDL deletes capability cash file", common.checkIfCapabilityCashFileExists, { false })
common.Step("Ignition on, Start SDL, HMI", common.start)
common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
