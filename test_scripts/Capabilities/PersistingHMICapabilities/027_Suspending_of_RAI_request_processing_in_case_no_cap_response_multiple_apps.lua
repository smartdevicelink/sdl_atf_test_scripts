---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL suspend of multiple RAI requests processing from mobile apps in case HMI capability cache file
--  exists on file system and ccpu_version matches with received ccpu_version from HMI
--
-- Preconditions:
-- 1. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
-- 2. HMI sends all capability to SDL
-- 3. SDL persists capability to HMI capabilities cache file ("hmi_capabilities_cache.json") in AppStorageFolder
-- 4. Ignition OFF/ON cycle performed
-- 5. SDL is started and send GetSystemInfo request
-- Sequence:
-- 1. Mobile App1 sends RegisterAppInterface request from Mobile device1 to SDL
--  a. SDL suspend of RAI request processing from mobile
-- 2. Mobile App2 sends RegisterAppInterface request from Mobile device1 to SDL
--  a. SDL suspend of RAI request processing from mobile
-- 3. Mobile App3 sends RegisterAppInterface request from Mobile device2 to SDL
--  a. SDL suspend of RAI requests processing from mobile
-- 4. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
--   SDL does not send HMI capabilities (VR/TTS/RC/UI etc) requests to HMI
--   a. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile App1
--   b. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile App2
--   c. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile App3
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local hmiCapabilities = common.getDefaultHMITable()
local anotherDeviceParams = { host = "1.0.0.1", port = config.mobilePort }
local appSessionId1 = 1
local appSessionId2 = 2
local appSessionId3 = 3
local mobConnId1 = 1
local mobConnId2 = 2
local ccpuVersion = "cppu_version_1"

local capRaiResponse = {
  buttonCapabilities = hmiCapabilities.Buttons.GetCapabilities.params.capabilities,
  vehicleType = hmiCapabilities.VehicleInfo.GetVehicleType.params.vehicleType,
  audioPassThruCapabilities = hmiCapabilities.UI.GetCapabilities.params.audioPassThruCapabilitiesList,
  hmiDisplayLanguage =  hmiCapabilities.UI.GetCapabilities.params.language,
  language = hmiCapabilities.VR.GetLanguage.params.language, -- or TTS.language
  pcmStreamCapabilities = hmiCapabilities.UI.GetCapabilities.params.pcmStreamCapabilities,
  hmiZoneCapabilities = hmiCapabilities.UI.GetCapabilities.params.hmiZoneCapabilities,
  softButtonCapabilities = hmiCapabilities.UI.GetCapabilities.params.softButtonCapabilities,
  displayCapabilities = hmiCapabilities.UI.GetCapabilities.params.displayCapabilities,
  vrCapabilities = hmiCapabilities.VR.GetCapabilities.params.vrCapabilities,
  speechCapabilities = hmiCapabilities.TTS.GetCapabilities.params.speechCapabilities,
  prerecordedSpeech = hmiCapabilities.TTS.GetCapabilities.params.prerecordedSpeechCapabilities
}

--[[ Local Functions ]]
local function noRequestsGetHMIParams(pVersion)
  local hmiValues = common.noRequestsGetHMIParams()
  hmiValues.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = pVersion,
      language = "EN-US",
      wersCountryCode = "wersCountryCode"
    }
  }
  return hmiValues
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updatedHMICapabilitiesFile)
common.Step("Start SDL, HMI", common.start, { common.updateHMISystemInfo(ccpuVersion) })
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect default device 1", common.startWoHMIonReady)
common.Step("Connect another mobile device 2 (Mobile 2)", common.connectMobDevice, { mobConnId2, anotherDeviceParams})
common.Step("Start services App1 on mobile device 1", common.startService, { appSessionId1, mobConnId1 })
common.Step("Start services App2 on mobile device 1", common.startService, { appSessionId2, mobConnId1 })
common.Step("Start services App3 on mobile device 2", common.startService, { appSessionId3, mobConnId2 })

common.Title("Test")
common.Step("Check suspending multiple Apps registration", common.registerAppsSuspend,
  { capRaiResponse, noRequestsGetHMIParams(ccpuVersion) })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
