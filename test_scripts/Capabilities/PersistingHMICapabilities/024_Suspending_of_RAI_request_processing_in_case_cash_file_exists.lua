---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL suspend of RAI request processing from mobile app in case HMI capability cache file
-- exists on file system and ccpu_version matches with received ccpu_version from HMI
--
-- Preconditions:
-- 1. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
-- 2. HMI sends all capability to SDL
-- 3. SDL persists capability to HMI capabilities cache file ("hmi_capabilities_cache.json") in AppStorageFolderr
-- 4. Ignition OFF/ON cycle performed
-- 5. SDL is started and send GetSystemInfo request
-- Sequence:
-- 1. Mobile sends RegisterAppInterface request to SDL
--  a. SDL suspend of RAI request processing from mobile
-- 2. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
--   SDL does not send HMI capabilities (VR/TTS/RC/UI etc) requests to HMI
--   SDL sends RegisterAppInterface response with corresponding capabilities (stored in hmi_capabilities_cache.json) to Mobile
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

common.Title("Test")
common.Step("Start SDL, HMI", common.startWoHMIonReady )
common.Step("Check suspending App registration", common.registerAppSuspend,
  { appSessionId, capRaiResponse, noRequestsGetHMIParams(ccpuVersion) })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
