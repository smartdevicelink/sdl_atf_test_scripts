---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL suspends of RAI request processing from mobile app until all HMI Capabilities
--  (VR/TTS/RC/UI/Buttons.GetCapabilities/,VR/TTS/UI.GetSupportedLanguages/GetLanguage, VehicleInfo.GetVehicleType)
--  are received from HMI in case mobile device connected during OnReady communication,
--  HMI capabilities cache file (hmi_capabilities_cache.json) exists on file system and ccpu_version do not match
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
-- 3. HMI sends all capabilities to SDL
-- 4. SDL persists capabilities to HMI capabilities cache file ("hmi_capabilities_cache.json") in AppStorageFolder
-- 5. Ignition OFF/ON cycle performed
-- 6. SDL is started and send GetSystemInfo request
-- Sequence:
-- 1. Mobile is connected just after HMI sends OnReady notification to SDL.
-- Mobile sends RegisterAppInterface request to SDL
--  a. SDL suspends of RAI request processing from mobile
-- 2. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_2" to SDL
--   a) SDL sends the requests to HMI for all capabilities
--   b) SDL deletes hmi capabilities cache file in AppStorageFolder
-- 3. HMI sends all HMI capabilities (VR/TTS/RC/UI etc) to SDL
--  a. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local delayRaiResponse = 9500

--[[ Local Functions ]]
local function updateHMISystemInfo(pVersion)
  local hmiCapabilities = common.getDefaultHMITable()
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

local function updateHMISystemInfoWithDelayResponse(pVersion)
  local hmiValues = common.getHMIParamsWithDelayResponse(delayRaiResponse)
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
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile)
common.Step("Start SDL, HMI, connect mobile", common.start, { updateHMISystemInfo("cppu_version_1") })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI", common.startWoBothHMIonReadyAndMobile)
common.Step("Check that capabilities file exists", common.checkIfCapabilityCacheFileExists)
common.Step("Connect mobile and check suspending App registration", common.connectMobileAndRegisterAppSuspend,
  { appSessionId, common.buildCapRaiResponse(), updateHMISystemInfoWithDelayResponse("cppu_version_2"),
    delayRaiResponse })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
