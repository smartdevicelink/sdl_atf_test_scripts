---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is send all requests for capability to HMI after Ignition ON in case
-- "hmi_capabilities_cache.json" file doesn't exist in AppStorageFolder
--
-- Preconditions:
-- 1) Check that file with capability file doesn't exist on file system
-- 2) SDL and HMI are started
-- 3) HMI sends all capability to SDL
-- 4) SDL stored capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 5) HMI sends IGNITION_OFF
-- 6) Remove "hmi_capabilities_cache.json" file from AppStorageFolder
-- Steps:
-- 1) Ignition ON
-- SDL does:
-- - a) check if hmi_capabilities_cache.json file present in AppStorageFolder
-- - b) requested all capability from HMI
-- Steps:
-- 2) HMI sends all capability to SDL
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
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Delete HMICapabilitiesCacheFile", common.deleteHMICapabilitiesCacheFile)
common.Step("Ignition on, Start SDL, HMI", common.start)
common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
