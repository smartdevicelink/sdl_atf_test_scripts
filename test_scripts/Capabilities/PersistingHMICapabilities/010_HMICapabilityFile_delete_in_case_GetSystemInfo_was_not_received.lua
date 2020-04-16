---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is requested all capability in case HMI does not send BC.GetSystemInfo notification
--
-- Preconditions:
-- 1. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
-- 2. HMI sends all capability to SDL
-- 3. SDL persists capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 4. Ignition OFF/ON cycle performed
-- 5. SDL is started and send GetSystemInfo request
-- Sequence:
-- 1. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_2" to SDL
--   a) send requested to HMI for all capability
--   b) delete hmi capability cache file in AppStorageFolder

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Functions ]]
local function noResponseGetHMIParams(pVersion)
  local hmiValues = common.noResponseGetHMIParams()
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
  common.start, { noResponseGetHMIParams("cppu_version_2") })
common.Step("Check that capability file doesn't exist", common.checkIfCapabilityCashFileExists, { false })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
