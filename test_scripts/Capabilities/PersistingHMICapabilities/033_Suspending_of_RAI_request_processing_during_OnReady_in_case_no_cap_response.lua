---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL suspends of RAI request processing from mobile app in case mobile device connected during OnReady
--   communication, HMI does not provide all HMI capabilities (VR/TTS/RC/UI etc) and ccpu_version do not match
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file doesn't exist on file system
-- 3. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
-- Sequence:
-- 1. Mobile is connected just after HMI sends OnReady notification to SDL.
-- Mobile sends RegisterAppInterface request to SDL
--  a. SDL suspends of RAI request processing from mobile
-- 2. HMI does not provide all HMI capabilities (VR/TTS/RC/UI etc)
--  a. SDL sends RegisterAppInterface response with corresponding capabilities (stored in hmi_capabilities.json)
--  from HMI to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local hmiCapabilities = common.getHMICapabilitiesFromFile()
local delayRaiResponse = 10000

--[[ Local Functions ]]
local function changeInternalNameRate(pCapabilities)
  local capTable = common.cloneTable(pCapabilities)
    capTable.bitsPerSample = string.gsub(capTable.bitsPerSample, "RATE_", "")
    capTable.samplingRate = string.gsub(capTable.samplingRate, "RATE_", "")
  return capTable
end

local function changeInternalNameRateArray(pCapabilities)
  local capTableArray = common.cloneTable(pCapabilities)
  for key, value in ipairs(capTableArray) do
    capTableArray[key] = changeInternalNameRate(value)
  end
  return capTableArray
end

local capRaiResponse = {
  buttonCapabilities = hmiCapabilities.Buttons.capabilities,
  vehicleType = hmiCapabilities.VehicleInfo.vehicleType,
  audioPassThruCapabilities = changeInternalNameRateArray(hmiCapabilities.UI.audioPassThruCapabilities),
  hmiDisplayLanguage =  hmiCapabilities.UI.language,
  language = hmiCapabilities.VR.language, -- or TTS.language
  pcmStreamCapabilities = changeInternalNameRate(hmiCapabilities.UI.pcmStreamCapabilities),
  hmiZoneCapabilities = { hmiCapabilities.UI.hmiZoneCapabilities },
  softButtonCapabilities = hmiCapabilities.UI.softButtonCapabilities,
  displayCapabilities = common.buildDisplayCapForMobileExp(hmiCapabilities.UI.displayCapabilities),
  vrCapabilities = hmiCapabilities.VR.vrCapabilities,
  speechCapabilities = hmiCapabilities.TTS.speechCapabilities,
  prerecordedSpeech = hmiCapabilities.TTS.prerecordedSpeechCapabilities
}

local function getHMIParamsWithOutResponse(pVersion)
  local hmiValues = common.getHMIParamsWithOutResponse()
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
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile, { true })
common.Step("Start SDL, HMI", common.startWoBothHMIonReadyAndMobile)

common.Title("Test")
common.Step("Connect mobile and check suspending App registration", common.connectMobileAndRegisterAppSuspend,
  { appSessionId, capRaiResponse, getHMIParamsWithOutResponse("cppu_version_1"), delayRaiResponse })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
