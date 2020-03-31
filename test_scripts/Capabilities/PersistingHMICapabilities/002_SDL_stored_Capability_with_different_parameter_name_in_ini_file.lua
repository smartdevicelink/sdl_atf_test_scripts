---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL creates capability cache file in AppStorageFolder in case
-- HMICapabilitiesCacheFile parameter has different value in smartDeviceLink.ini
--
-- Preconditions:
-- 1. hmi_capabilities_cache.json file doesn't exist on file system
-- 2. Update HMICapabilitiesCacheFile parameter value in smartDeviceLink.ini file
-- 3. SDL and HMI are started
-- Sequence:
-- 1. HMI sends "BasicCommunication.OnReady" notification
--  a request all capability from HMI
-- 2. HMI sends all capability to SDL
--  a. created file for capability with different names
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local cacheFileNames = { "hmi_capabilities.json", "file.txt", "json" }

--[[ Scenario ]]
for _, cashFile in pairs(cacheFileNames) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Update HMICapabilitiesCacheFile in SDL.ini file " .. cashFile, common.setSDLIniParameter,
    { "HMICapabilitiesCacheFile", cashFile })

  common.Title("Test")
  common.Step("Start SDL, HMI", common.start)
  common.Step("Check that SDL creates capability file with name-" .. cashFile,
    common.checkIfCapabilityCashFileExists, { true, cashFile })
  common.Step("Ignition off", common.ignitionOff)
  common.Step("Ignition on, SDL doesn't send HMI capabilities requests",
  common.start, { common.noRequestsGetHMIParams() })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
