---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL creates capability cache file in AppStorageFolder in case
-- HMICapabilitiesCacheFile parameter has different value in smartDeviceLink.ini
--
-- Preconditions:
-- 1) hmi_capabilities_cache.json file doesn't exist on file system
-- 2) Update HMICapabilitiesCacheFile parameter value in smartDeviceLink.ini file
-- 3) SDL and HMI are started
-- Steps:
-- 1) HMI sends "BasicCommunication.OnReady" notification
-- SDL does:
-- - a) request all capability from HMI
-- Steps:
-- 2) HMI sends all capability to SDL
-- SDL does:
-- - a) created file for capability with different names
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local cacheFileNames = { "hmi_capabilities.json", "cash.json", "12345.json" }

--[[ Scenario ]]
for _, value in pairs(cacheFileNames) do
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Update HMICapabilitiesCacheFile in SDL.ini file " .. value, common.setSDLIniParameter,
    { "HMICapabilitiesCacheFile", value })

  common.Title("Test")
  common.Step("Start SDL, HMI", common.start)
  common.Step("Check that SDL creates capability file with name-" .. value,
    common.checkIfExistCapabilityFile, { value })
  common.Step("Ignition off", common.ignitionOff)
  common.Step("Ignition on, SDL doesn't send HMI capabilities requests",
  common.start, { common.noRequestsGetHMIParam() })

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
