---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL deletes HMI capability cache (hmi_capabilities_cache.json) file during MASTER_RESET
--
-- Preconditions:
-- 1. Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capability cache file (hmi_capabilities_cache.json) doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. All HMI Capabilities (VR/TTS/RC/UI etc) are presented in hmi_capabilities_cache.json
-- Sequence:
-- 1. HMI sends OnExitAllApplications with reason MASTER_RESET
-- - a. SDL deletes "hmi_capabilities_cache.json" file in AppStorageFolder
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI provides HMI capabilities", common.start)
common.Step("Validate stored capability file", common.checkContentOfCapabilityCacheFile)

common.Title("Test")
common.Step("Shutdown by MASTER_RESET", common.masterReset)
common.Step("Check that SDL deletes HMI capability cache file", common.checkIfCapabilityCacheFileExists, { false })
common.Step("Ignition on, SDL sends HMI capabilities requests to HMI", common.start)
common.Step("Validate stored capability file", common.checkContentOfCapabilityCacheFile)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
