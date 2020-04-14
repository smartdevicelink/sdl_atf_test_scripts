---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL updates "hmi_capabilities_cache.json" file if HMI sends
--  TTS/VR/UI.OnLanguageChange notification with appropriate language
--
-- Preconditions:
-- 1. hmi_capabilities_cache.json file doesn't exist on file system
-- 2. SDL and HMI are started
-- 3. HMI sends all HMI capability to SDL
-- 4. SDL persists capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- Sequence:
-- 1. HMI sends "TTS/VR/UI.OnLanguageChange" notifications with language to SDL
--  a. override TTS/VR/UI.language in "hmi_capabilities_cache.json" file
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
  common.Step("Check stored value to cache file", common.updateHMILanguageCapability, { pLanguage })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
