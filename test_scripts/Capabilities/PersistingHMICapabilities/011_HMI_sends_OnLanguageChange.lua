---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL updates "hmi_capabilities_cache.json" file if HMI sends
--  TTS/VR/UI.OnLanguageChange notification with appropriate language
--
-- Preconditions:
-- 1) hmi_capabilities_cache.json file doesn't exist on file system
-- 2) SDL and HMI are started
-- 2) HMI sends all HMI capability to SDL
-- 3) SDL persists capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- Steps:
-- 1) HMI sends "TTS/VR/UI.OnLanguageChange" notifications with language to SDL
-- SDL does:
--   a) override TTS/VR/UI.language in "hmi_capabilities_cache.json" file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')


--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start, { common.updateHMILanguage("EN-US") })

common.Title("Test")
common.Step("OnLanguageChange notification", common.onLanguageChange, { "FR-FR" })
common.Step("Check stored value to cache file", common.checkLanguageCapability, { "FR-FR" })

common.Step("OnLanguageChange notification", common.onLanguageChange, { "DE-DE" })
common.Step("Check stored value to cache file", common.checkLanguageCapability, { "DE-DE" })

common.Step("OnLanguageChange notification", common.onLanguageChange, { "EN-US" })
common.Step("Check stored value to cache file", common.checkLanguageCapability, { "EN-US" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
