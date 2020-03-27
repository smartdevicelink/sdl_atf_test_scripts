---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that the SDL takes default parameters from hmi_capabilities.json in case
-- HMI does not provide successful GetCapabilities/GetLanguage/GetVehicleType responses due to timeout

-- Preconditions:
-- 1) hmi_capabilities_cache.json file doesn't exist on file system
-- 2) HMI and SDL are started
-- Steps:
-- 1) HMI does not provide any Capability
-- SDL does:
--  a) use default capability from hmi_capabilities.json file
--  b) not persist default capabilities in cache file
-- 2) IGN_OFF/IGN_ON
-- SDL does:
--  a) cached of all capability
--  b) created HMICapabilitiesCache file with all capability on file system
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Functions ]]
-- local function hmiDefaultData()
--     local hmiCapabilities = common.getHMICapabilitiesFromFile()
--   -- local path_to_file = config.pathToSDL .. "/hmi_capabilities.json"
--   -- local defaulValue = common.jsonFileToTable(path_to_file)
--   -- return defaulValue
--     return hmiCapabilities
-- end

local function changeBitsPSEnumPcmCap(pCapabilities)
  local bitsPerSampleEnum = common.cloneTable(pCapabilities)
  for pKey, value in pairs(bitsPerSampleEnum) do
    if pKey == "bitsPerSample" then
       bitsPerSampleEnum.bitsPerSample = string.gsub(value, "RATE_", "")
    end
  end
  return bitsPerSampleEnum
end

local function changeBitsPSEnumAudioCap(pCapabilities)
  local bitsPerSampleEnum = common.cloneTable(pCapabilities)
  for _, value in ipairs(bitsPerSampleEnum) do
    for pKey, pValue in pairs(value) do
      if pKey == "bitsPerSample" then
        value.bitsPerSample = string.gsub(pValue, "RATE_", "")
      end
    end
  end
  return bitsPerSampleEnum
end

--[[ Local Variables ]]
local hmiCapabilities = common.getHMICapabilitiesFromFile()

local capRaiResponse = {
  buttonCapabilities = hmiCapabilities.Buttons.capabilities,
  vehicleType = hmiCapabilities.VehicleInfo.vehicleType,
  audioPassThruCapabilities = changeBitsPSEnumAudioCap(hmiCapabilities.UI.audioPassThruCapabilities),
  hmiDisplayLanguage =  hmiCapabilities.UI.language,
  language = hmiCapabilities.VR.language, -- or TTS.language
  pcmStreamCapabilities = changeBitsPSEnumPcmCap(hmiCapabilities.UI.pcmStreamCapabilities),
  hmiZoneCapabilitie = hmiCapabilities.UI.hmiZoneCapabilitie,
  softButtonCapabilities = hmiCapabilities.UI.softButtonCapabilities,
  displayCapabilities = hmiCapabilities.UI.displayCapabilities,
  vrCapabilities = hmiCapabilities.VR.capabilities,
  speechCapabilities = hmiCapabilities.TTS.capabilities
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Check that capability file doesn't exist", common.checkIfDoesNotExistCapabilityFile) -- to common

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI", common.start, { common.noResponseGetHMIParam() })
common.Step("Check that capability file doesn't exist", common.checkIfDoesNotExistCapabilityFile)
common.Step("App registration", common.registerApp, { 1, capRaiResponse })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
