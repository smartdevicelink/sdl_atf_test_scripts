---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL doesn't create "hmi_capabilities_cache.json" file in AppStorageFolder in case
-- HMICapabilitiesCacheFile parameter has incorrect value in smartDeviceLink.ini
--
-- Preconditions:
-- 1. hmi_capabilities_cache.json file doesn't exist on file system
-- 2. Update HMICapabilitiesCacheFile parameter value in smartDeviceLink.ini file
-- 3. SDL and HMI are started
-- Sequence:
-- 1. HMI sends "BasicCommunication.OnReady" notification
--  a. request all capability from HMI
-- 2. HMI sends all capability to SDL
--  a. not created file for capability with incorrect name
--  b. not stored capability to file in AppStorageFolder
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
  common.Step("Start SDL and HMI", common.start)
  common.Step("Ignition off", common.ignitionOff)
  common.Step("Ignition on, SDL sends HMI capabilities requests", common.start)

  common.Title("Postconditions")
  common.Step("Stop SDL", common.postconditions)
end
