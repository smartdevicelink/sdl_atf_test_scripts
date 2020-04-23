---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL does not create HMI capability cache file (hmi_capabilities_cache.json) in AppStorageFolder
-- in case HMI does not provide all HMI capabilities (VR/TTS/RC/UI etc)
--
-- Preconditions:
-- 1. Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capability cache file (hmi_capabilities_cache.json) doesn't exist on file system
-- 3. SDL and HMI are started
-- Sequence:
-- 1. HMI does not provide all HMI capabilities (VR/TTS/RC/UI etc)
--  a. SDL does not create "hmi_capabilities_cache.json" file in AppStorageFolder
-- 2. Ignition OFF/ON cycle performed
--  a. SDL sends HMI capabilities (VR/TTS/RC/UI etc) requests to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI does not provide HMI capabilities",
  common.start, { common.noResponseGetHMIParams() })
common.Step("Check that capability file doesn't exist", common.checkIfCapabilityCacheFileExists, { false })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, SDL sends all HMI capabilities requests",
  common.start, { common.noResponseGetHMIParams() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
