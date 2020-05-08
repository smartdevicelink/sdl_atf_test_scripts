---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL persists (VR/TTS/UI) languages in "hmi_capabilities_cache.json" file in case HMI sends
--  TTS/VR/UI.OnLanguageChange notification with appropriate language
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file (hmi_capabilities_cache.json) file file doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI does not provide any capabilities
-- Sequence:
-- 1. HMI sends "TTS/VR/UI.OnLanguageChange" notifications with language to SDL
--  a. SDL persists TTS/VR/UI.language in "hmi_capabilities_cache.json" file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start, { common.getHMIParamsWithOutResponse()})
common.Step("Check that capabilities file doesn't exist", common.checkIfCapabilityCacheFileExists, { false })

common.Title("Test")
common.Step("OnLanguageChange notification FR-FR", common.changeLanguage, { "FR-FR" })
common.Step("Check stored value to cache file", common.checkLanguageCapability, { "FR-FR" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
