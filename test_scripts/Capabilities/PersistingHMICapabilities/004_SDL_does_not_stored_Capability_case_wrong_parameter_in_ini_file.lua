---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Processing of HMICapabilitiesCacheFile parameter in SmartDeviceLink.ini if this variable is null/empty
--
-- Preconditions:
-- 1. HMI capabilities cache file doesn't exist on file system
-- 2. Update HMICapabilitiesCacheFile parameter value in smartDeviceLink.ini file
-- 3. SDL and HMI are started
-- Sequence:
-- 1. HMI sends all HMI capabilities (VR/TTS/RC/UI/Buttons/VehicleInfo etc)
--   a. SDL does not persists all HMI Capabilities to corresponding file in AppStorageFolder
-- 2. Ignition OFF/ON cycle performed
--   a. SDL sends HMI capabilities (VR/TTS/RC/UI etc) requests to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local hmiCacheFile = {
  commented_out = ";",
  undefined = ""
}

--[[ Scenario ]]
for k, value in pairs(hmiCacheFile) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Update HMICapabilitiesCacheFile in SDL.ini file " .. k, common.setSDLIniParameter,
    { "HMICapabilitiesCacheFile", value })

  common.Title("Test")
  common.Step("Start SDL and HMI, SDL sends HMI capabilities requests", common.start)
  common.Step("Ignition off", common.ignitionOff)
  common.Step("Ignition on, SDL sends HMI capabilities requests", common.start)

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
