---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Processing of HMICapabilitiesCacheFile parameter in SmartDeviceLink.ini
--
-- Preconditions:
-- 1. Value of HMICapabilitiesCacheFile parameter is changed in smartDeviceLink.ini file
-- 2. SDL and HMI are started
-- Sequence:
-- 1. HMI sends all HMI capabilities (VR/TTS/RC/UI/Buttons/VehicleInfo etc)
--   a. SDL persists all HMI Capabilities to corresponding file in AppStorageFolder
-- 2. Ignition OFF/ON cycle performed
--   a. SDL does not send HMI capabilities (VR/TTS/RC/UI/Buttons/VehicleInfo etc) requests to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local cacheFileNames = { "hmi_capabilities.json", "file.txt", "json" }

--[[ Scenario ]]
for _, cacheFile in pairs(cacheFileNames) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Update HMICapabilitiesCacheFile in SDL.ini file " .. cacheFile, common.setSDLIniParameter,
    { "HMICapabilitiesCacheFile", cacheFile })

  common.Title("Test")
  common.Step("Start SDL, HMI", common.start)
  common.Step("Check that SDL creates capability file with name-" .. cacheFile,
    common.checkIfCapabilityCacheFileExists, { true, cacheFile })
  common.Step("Ignition off", common.ignitionOff)
  common.Step("Ignition on, SDL doesn't send HMI capabilities requests",
  common.start, { common.noRequestsGetHMIParams() })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
