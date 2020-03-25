---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is requested all capability in case HMI sends BC.GetSystemInfo notification with
-- incorrect data
--
-- Preconditions:
-- 1) Check that file with capability file doesn't exist on file system
-- 2) SDL and HMI are started
-- 3) HMI sends all capability to SDL
-- 4) SDL stored capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 5) Ignition OFF/ON cycle performed
-- 6) SDL is started and send GetSystemInfo request
-- Steps:
-- 1) HMI sends "BasicCommunication.GetSystemInfo" notification with incorrect data
-- SDL does:
-- - a) send requested to HMI for all capability
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Functions ]]
local function updateHMIValue()
  local hmiValues = common.getDefaultHMITable()
  hmiValues.BasicCommunication.GetSystemInfo = {
    params = { 1 }  -- Incorrect data
  }
  return hmiValues
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment check HMICapabilitiesCacheFile", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends GetSystemInfo notification with incorrect data",
  common.start, { updateHMIValue() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
