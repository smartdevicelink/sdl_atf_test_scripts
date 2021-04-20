---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is requested all capabilities in case HMI does not send BC.GetSystemInfo notification
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file (hmi_capabilities_cache.json) doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI sends all HMI capabilities
-- 5. HMI sends GetSystemInfo with ccpu_version = "New_ccpu_version_1" to SDL
-- 6. SDL stored capabilities to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 7. Ignition OFF/ON cycle performed
-- Sequence:
-- 1. HMI does not send "BasicCommunication.GetSystemInfo" response
-- - a. SDL sends all HMI capabilities request (VR/TTS/RC/UI etc) to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Functions ]]
local function noResponseGetSystemInfo()
  local hmiCapabilities = common.getDefaultHMITable()
  hmiCapabilities.BasicCommunication.GetSystemInfo = nil
  return hmiCapabilities
end

local function startNoResponseGetSystemInfo()
  common.start(noResponseGetSystemInfo())
  :Timeout(15000) -- because of SDL delays requests of capabilities
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start, { common.updateHMISystemInfo("cppu_version_1") })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI does not send GetSystemInfo notification",
  startNoResponseGetSystemInfo)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
