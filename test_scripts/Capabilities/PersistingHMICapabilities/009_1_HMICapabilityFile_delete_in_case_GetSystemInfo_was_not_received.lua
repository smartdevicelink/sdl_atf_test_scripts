---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is requested all capability in case HMI does not send BC.GetSystemInfo notification
--
-- Preconditions:
-- 1. hmi_capabilities_cache.json file doesn't exist on file system
-- 2. Check that file with capability file doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI sends all capability to SDL
-- 5. SDL persists capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 6. Ignition OFF/ON cycle performed
-- 7. SDL is started and send GetSystemInfo request
-- Sequence:
-- 1. HMI does not send "BasicCommunication.GetSystemInfo" notification
-- - a) send requested to HMI for all capability
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Functions ]]
local function noResponseGetSystemInfo()
  local hmiCapabilities = common.noResponseGetHMIParams()
  hmiCapabilities.BasicCommunication.GetSystemInfo = nil
  return hmiCapabilities
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start, { common.updateHMISystemInfo("cppu_version_1") })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI does not send GetSystemInfo notification",
  common.start, { noResponseGetSystemInfo() })
common.Step("Check that capability file doesn't exist", common.checkIfCapabilityCashFileExists, { false })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
