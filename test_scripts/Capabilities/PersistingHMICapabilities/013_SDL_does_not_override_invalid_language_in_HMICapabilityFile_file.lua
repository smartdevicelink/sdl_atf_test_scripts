---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL does not override in "hmi_capabilities_cache.json" file
-- in case HMI sends TTS/VR/UI.OnLanguageChange notification with invalid language
-- Preconditions:
-- 1. hmi_capabilities_cache.json file doesn't exist on file system
-- 2. SDL and HMI are started
-- 3. HMI sends all HMI capability to SDL
-- Sequence:
-- 1. HMI sends "TTS/VR/UI.OnLanguageChange" notifications with invalid language to SDL
--   a. SDL does not override TTS/VR/UI.language in "hmi_capabilities_cache.json" file
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
common.Step("Check stored value to cache file", common.updateHMILanguageCapability, { "EN-US" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
