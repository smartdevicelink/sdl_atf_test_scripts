---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL creates new capability cache file in AppStorageFolder in second
-- ignition cycle
--
-- Preconditions:
-- 1. HMI capability cash file (hmi_capabilities_cache.json) exists on file system
-- Sequence:
-- 1. SDL and HMI are started
--  SDL sends all HMI capabilities request (VR/TTS/RC/UI etc) to HMI
-- 2. HMI sends all HMI capabilities (VR/TTS/RC/UI etc)
--  a. SDL persists HMI capabilities to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 2. Ignition OFF
-- 3. Update HMICapabilitiesCacheFile parameter value in smartDeviceLink.ini file
-- 4. Ignition On, Start SDL and HMI
--  a. SDL sends all HMI capabilities request (VR/TTS/RC/UI etc)
-- 5. HMI sends all HMI capabilities (VR/TTS/RC/UI etc)
--  a. SDL persists capabilities to "NEW_hmi_capabilities_cache.json" file in AppStorageFolder
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMICapabilitiesCacheFile in SDL.ini file ", common.setSDLIniParameter,
  { "HMICapabilitiesCacheFile", "hmi_capabilities_cash.json" })

common.Title("Test")
common.Step("Start SDL and HMI", common.start)
common.Step("Check that HMI capability cash file exists: hmi_capabilities_cash.json",
  common.checkIfCapabilityCashFileExists, { true, "hmi_capabilities_cash.json" })
common.Step("Ignition off", common.ignitionOff)
common.Step("Update HMICapabilitiesCacheFile in SDL.ini file ", common.setSDLIniParameter,
  { "HMICapabilitiesCacheFile", "NEW_hmi_capabilities_cash.json" })
common.Step("Ignition on, Start SDL, HMI", common.start)
common.Step("Check that HMI capability cash file exists: new_hmi_capabilities_cash.json",
  common.checkIfCapabilityCashFileExists, { true, "NEW_hmi_capabilities_cash.json" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
