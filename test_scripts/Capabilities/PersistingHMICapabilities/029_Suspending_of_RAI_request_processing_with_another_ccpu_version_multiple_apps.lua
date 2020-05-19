---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL suspend of multiple RAI requests processing from mobile apps until all HMI Capabilities
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
-- 1. Mobile App1 sends RegisterAppInterface request from Mobile device1 to SDL
--  a. SDL suspend of RAI request processing from mobile
-- 2. Mobile App2 sends RegisterAppInterface request from Mobile device1 to SDL
--  a. SDL suspend of RAI request processing from mobile
-- 3. Mobile App3 sends RegisterAppInterface request from Mobile device2 to SDL
--  a. SDL suspend of RAI requests processing from mobile device
-- 4. HMI sends all HMI capabilities (VR/TTS/RC/UI etc) to SDL
--  a. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile App1
--  b. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile App2
--  c. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile App3
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local anotherDeviceParams = { host = "1.0.0.1", port = config.mobilePort }
local appSessionId1 = 1
local appSessionId2 = 2
local appSessionId3 = 3
local mobConnId1 = 1
local mobConnId2 = 2
local delayRaiResponse = 9500


--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile)
common.Step("Start SDL, HMI, connect default device 1", common.startWoHMIonReady)
common.Step("Connect another mobile device (Mobile 2)", common.connectMobDevice, { mobConnId2, anotherDeviceParams})
common.Step("Start service App1 on mobile device 1", common.startService, { appSessionId1, mobConnId1 })
common.Step("Start service App2 on mobile device 1", common.startService, { appSessionId2, mobConnId1 })
common.Step("Start service App3 on mobile device 2", common.startService, { appSessionId3, mobConnId2 })

common.Title("Test")
common.Step("Check suspending multiple Apps registration", common.registerAppsSuspend,
  { common.buildCapRaiResponse(), common.getHMIParamsWithDelayResponse(), delayRaiResponse })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
common.Step("Remove additional connection", common.deleteMobDevices, { mobConnId2 })
