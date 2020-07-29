---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL use capabilities stored in hmi_capabilities_cache.json
--  SDL sends RegisterAppInterface response with all capabilities stored in hmi_capabilities_cache.json
-- on RegisterAppInterface request from Mobile App
--
-- Preconditions:
-- 1. Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file (hmi_capabilities_cache.json) exists on file system
-- 3. All HMI Capabilities (VR/TTS/RC/UI etc) are presented in hmi_capabilities_cache.json
-- 4. SDL and HMI are started
-- Sequence:
-- 1. Mobile sends RegisterAppInterface request to SDL
--  a. SDL sends RegisterAppInterface response with correspond capabilities (stored in hmi_capabilities_cache.json)
--  to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile)

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI", common.start)
common.Step("Check that capabilities file exists", common.checkIfCapabilityCacheFileExists)
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, HMI, SDL doesn't send HMI capabilities requests to HMI",
  common.start, { common.getHMIParamsWithOutRequests() })
common.Step("App registration", common.registerApp, { appSessionId, common.buildCapRaiResponse() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
