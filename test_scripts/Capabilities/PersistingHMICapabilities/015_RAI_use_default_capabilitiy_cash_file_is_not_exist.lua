---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that the SDL takes default parameters from hmi_capabilities.json in case
-- HMI does not send successful GetCapabilities/GetLanguage/GetVehicleType responses due to timeout

-- Preconditions:
-- 1. HMI and SDL are started
-- Sequence:
-- 1. HMI does not provide any Capability
--  a. use default capability from hmi_capabilities.json file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local hmiCapabilities = common.getHMICapabilitiesFromFile()

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
  hmiZoneCapabilities = hmiCapabilities.UI.hmiZoneCapabilities,
  softButtonCapabilities = hmiCapabilities.UI.softButtonCapabilities,
  displayCapabilities = hmiCapabilities.UI.displayCapabilities,
  vrCapabilities = hmiCapabilities.VR.capabilities,
  speechCapabilities = hmiCapabilities.TTS.capabilities
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI", common.start, { common.noResponseGetHMIParams() })
common.Step("Check that capability file doesn't exist", common.checkIfCapabilityCashFileExists, { false })
common.Step("App registration", common.registerApp, { appSessionId, capRaiResponse })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
