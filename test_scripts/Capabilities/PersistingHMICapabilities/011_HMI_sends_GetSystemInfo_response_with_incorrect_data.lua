---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is requested all capabilities in case HMI sends BC.GetSystemInfo notification with
-- incorrect data
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file (hmi_capabilities_cache.json) doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI sends all HMI capabilities
-- 5. SDL stored capabilities to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 6. Ignition OFF/ON cycle performed
-- Sequence:
-- 5. HMI sends "BasicCommunication.GetSystemInfo" response without mandatory parameter: "ccpu_version"/
--   invalid parameter type
--  a. SDL sends all HMI capabilities request (VR/TTS/RC/UI etc) to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local invalidTypeCcpuVersion = 1

--[[ Local Functions ]]
local function getHMIParamsWithOutRequests(pVersion)
  return common.getHMIParamsWithOutRequests(common.updateHMISystemInfo(pVersion))
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start, { common.updateHMISystemInfo("cppu_version_1") })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends GetSystemInfo notification with invalid parameter type",
  common.start, { common.updateHMISystemInfo(invalidTypeCcpuVersion) })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends the same cppu_version_1",
  common.start, { getHMIParamsWithOutRequests("cppu_version_1") })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, HMI sends GetSystemInfo notification without mandatory parameter ccpu_version",
  common.start, { common.updateHMISystemInfo() })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends the same cppu_version_1",
  common.start, { getHMIParamsWithOutRequests("cppu_version_1") })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

