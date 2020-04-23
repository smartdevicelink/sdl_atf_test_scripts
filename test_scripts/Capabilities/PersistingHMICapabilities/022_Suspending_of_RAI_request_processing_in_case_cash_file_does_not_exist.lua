---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL suspend of RAI request processing from mobile app until all HMI Capabilities
--  (VR/TTS/RC/UI/Buttons.GetCapabilities/,VR/TTS/UI.GetSupportedLanguages/GetLanguage, VehicleInfo.GetVehicleType)
--  are received from HMI in case HMI capability cache file (hmi_capabilities_cache.json) doesn't exist on file system
--
-- Preconditions:
-- 1. HMI capabilities cache file doesn't exist on file system
-- 2. SDL and HMI are started
-- 3. HMI sends all HMI capabilities (VR/TTS/RC/UI etc) to SDL
-- 4. Local ccpu_version matches with received ccpu_version from HMI
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
local ccpuVersion = "cppu_version_1"
local hmiCapabilities = common.getDefaultHMITable()

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
local function noResponseGetHMIParams(pVersion)
  local hmiValues = common.noResponseGetHMIParams()
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
common.Step("Start SDL, HMI", common.start, { noResponseGetHMIParams(ccpuVersion) })
common.Step("Check that capability file doesn't exist", common.checkIfCapabilityCacheFileExists, { false })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI", common.startWoHMIonReady, { common.updateHMISystemInfo(ccpuVersion) })
common.Step("Check suspending App registration", common.registerAppSuspend,
  { appSessionId, capRaiResponse, common.updateHMISystemInfo(ccpuVersion)})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
