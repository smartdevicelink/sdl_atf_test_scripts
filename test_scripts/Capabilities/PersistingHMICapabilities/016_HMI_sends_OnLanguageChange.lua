---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL updates "hmi_capabilities_cache.json" file if HMI sends
--  TTS/VR/UI.OnLanguageChange notification with appropriate language
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file (hmi_capabilities_cache.json) doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI sends all HMI capabilities to SDL
-- 5. SDL persists capabilities to HMI capabilities cache file (hmi_capabilities_cache.json) in AppStorageFolder
-- Sequence:
-- 1. HMI sends "TTS/VR/UI.OnLanguageChange" notifications with language to SDL
--  a. SDL overrides TTS/VR/UI.language in HMI capabilities cache file (hmi_capabilities_cache.json)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local language = { "FR-FR", "DE-DE", "EN-US" }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start, { common.updateHMILanguageCapability("EN-US") })

common.Title("Test")

for _, pLanguage in pairs(language) do
  common.Step("OnLanguageChange notification " .. pLanguage , common.changeLanguage, { pLanguage })
  common.Step("Check stored value to cache file", common.checkLanguageCapabilityInCache, { pLanguage })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
