---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL suspend of RAI request processing from mobile app until all HMI Capabilities
--  (VR/TTS/RC/UI/Buttons.GetCapabilities/,VR/TTS/UI.GetSupportedLanguages/GetLanguage, VehicleInfo.GetVehicleType)
--  are received from HMI in case ccpu_version do not match
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI sends all HMI capabilities (VR/TTS/RC/UI etc) to SDL
-- 5. HMI sends "BasicCommunication.GetSystemInfo" response with the other ccpu_version than SDL has in its LPT
-- Sequence:
-- 1. Mobile sends RegisterAppInterface request to SDL
--  a. SDL suspend of RAI request processing from mobile
-- 2. HMI sends all HMI capabilities (VR/TTS/RC/UI etc) to SDL
--  a. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile)
common.Step("Start SDL, HMI", common.startWoHMIonReady)

common.Title("Test")
common.Step("Check suspending App registration", common.registerAppSuspend,
  { appSessionId, common.buildCapRaiResponse(), common.updateHMISystemInfo("cppu_version_1") })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
