---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is delete "hmi_capabilities_cache.json" file during MASTER_RESET
--
-- Preconditions:
-- 1) Check that file with capability file doesn't exist on file system
-- 2) SDL and HMI are started
-- 3) HMI sends all capability to SDL
-- 4) SDL stored capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- Steps:
-- 1) HMI sends OnExitAllApplications with reason MASTER_RESET
-- SDL does:
-- - a) deleted "hmi_capabilities_cache.json" file in AppStorageFolder
-- Steps:
-- 2) Ignition ON
-- SDL does:
-- - a) check if hmi_capabilities_cache.json file present in AppStorageFolder
-- - b) requested all capability from HMI
-- Steps:
-- 3) HMI sends all capability to SDL
-- SDL does:
-- - a) stored all capability to "hmi_capabilities_cache.json" file in AppStorageFolder
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment check HMICapabilitiesCacheFile", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)

common.Title("Test")
common.Step("Shutdown by MASTER_RESET", common.masterReset)
common.Step("Check that SDL delete capability file", common.checkIfDoesNotExistCapabilityFile)
common.Step("Ignition on, Start SDL, HMI", common.start)
common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
