---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL deletes HMI capabilities cache (hmi_capabilities_cache.json)
--  in case ccpu_version do not match
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
-- 3. HMI sends all capabilities to SDL
-- 4. SDL persists capabilities to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 5. Ignition OFF/ON cycle performed
-- 6. SDL is started and send GetSystemInfo request
-- Sequence:
-- 1. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_2" to SDL
--   a) SDL sends requested to HMI for all capabilities
--   b) SDL deletes hmi capabilities cache file in AppStorageFolder
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Functions ]]
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
common.Step("Start SDL, HMI", common.start, { common.updateHMISystemInfo("cppu_version_1") })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, GetSystemInfo notification",
  common.start, { getHMIParamsWithOutResponse("cppu_version_2") })
common.Step("Check that capabilities file doesn't exist", common.checkIfCapabilityCacheFileExists, { false })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
