---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that the SDL takes default parameters from hmi_capabilities.json in case
-- HMI does not provide successful GetCapabilities/GetLanguage/GetVehicleType responses due to timeout

-- Preconditions:
-- 1) HMI and SDL are started
-- Steps:
-- 1) HMI does not provide any Capability
-- SDL does:
--  a) use default capability from hmi_capabilities.json file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local hmiCapabilities = common.getHMICapabilitiesFromFile()

--[[ Local Functions ]]
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

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI", common.start, { common.noResponseGetHMIParam() })
common.Step("Check that capability file doesn't exist", common.checkIfDoesNotExistCapabilityFile)
common.Step("App registration", common.registerApp, { appSessionId, capRaiResponse })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
