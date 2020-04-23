---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL suspend of RAI request processing from mobile app until all HMI Capabilities
--  (VR/TTS/RC/UI/Buttons.GetCapabilities/,VR/TTS/UI.GetSupportedLanguages/GetLanguage, VehicleInfo.GetVehicleType)
--  are received from HMI in case HMI capability cache file (hmi_capabilities_cache.json) exists on file system
-- and ccpu_version do not match
--
-- Preconditions:
-- 1. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
-- 2. HMI sends all capability to SDL
-- 3. SDL persists capability to HMI capabilities cache file ("hmi_capabilities_cache.json") in AppStorageFolder
-- 4. Ignition OFF/ON cycle performed
-- 5. SDL is started and send GetSystemInfo request
-- Sequence:
-- 1. Mobile sends RegisterAppInterface request to SDL
--  a. SDL suspend of RAI request processing from mobile
-- 2. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_2" to SDL
--   a) send requested to HMI for all capability
--   b) delete hmi capability cache file in AppStorageFolder
-- 3. HMI sends all HMI capabilities (VR/TTS/RC/UI etc) to SDL
--  a. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local hmiCapabilities = common.getDefaultHMITable()

local capRaiResponse = {
  buttonCapabilities = hmiCapabilities.Buttons.GetCapabilities.params.capabilities,
  vehicleType = hmiCapabilities.VehicleInfo.GetVehicleType.params.vehicleType,
  audioPassThruCapabilities = hmiCapabilities.UI.GetCapabilities.params.audioPassThruCapabilitiesList,
  hmiDisplayLanguage = hmiCapabilities.UI.GetCapabilities.params.language,
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
local function updateHMISystemInfo(pVersion)
  hmiCapabilities.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = pVersion,
      language = "EN-US",
      wersCountryCode = "wersCountryCode"
    }
  }
   table.remove(hmiCapabilities.Buttons.GetCapabilities.params.capabilities, 9)
  hmiCapabilities.VehicleInfo.GetVehicleType.params.vehicleType.modelYear = "2020"
  hmiCapabilities.UI.GetCapabilities.params.audioPassThruCapabilitiesList[1].samplingRate = "16KHZ"
  hmiCapabilities.UI.GetCapabilities.params.pcmStreamCapabilities.samplingRate = "16KHZ"
  hmiCapabilities.UI.GetCapabilities.params.hmiZoneCapabilities = "BACK"
  hmiCapabilities.UI.GetCapabilities.params.softButtonCapabilities.shortPressAvailable = false
  hmiCapabilities.UI.GetCapabilities.params.displayCapabilities =
  table.remove(hmiCapabilities.UI.GetCapabilities.params.displayCapabilities.textFields, 9)
  hmiCapabilities.VR.GetCapabilities.params.vrCapabilities[2] = "TEXT"
  hmiCapabilities.VR.GetCapabilities.params.vrCapabilities[3] = "TEXT"
  hmiCapabilities.TTS.GetCapabilities.params.prerecordedSpeechCapabilities = "POSITIVE_JINGLE"
  return hmiCapabilities
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updatedHMICapabilitiesFile)
common.Step("Start SDL, HMI", common.start, { common.updateHMISystemInfo("cppu_version_1") })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI", common.startWoHMIonReady)
common.Step("Check that capability file exists", common.checkIfCapabilityCacheFileExists)
common.Step("Check suspending App registration", common.registerAppSuspend,
  { appSessionId, capRaiResponse, updateHMISystemInfo("cppu_version_2") })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
