---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL does not override in "hmi_capabilities_cache.json" file
-- in case HMI sends TTS/VR/UI.OnLanguageChange notification with invalid language
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file (hmi_capabilities_cache.json) doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI sends all HMI capabilities to SDL
--
-- Sequence:
-- 1. HMI sends "TTS/VR/UI.OnLanguageChange" notifications with invalid language to SDL
--   a. SDL does not override TTS/VR/UI.language in HMI capabilities cache file ("hmi_capabilities_cache.json")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variable ]]
local invalidLanguage = "EN-EN"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start, { common.updateHMILanguageCapability("EN-US") })

common.Title("Test")
common.Step("OnLanguageChange notification invalid language EN-EN", common.changeLanguage, { invalidLanguage })
common.Step("Check stored value to cache file", common.checkLanguageCapability, { "EN-US" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
