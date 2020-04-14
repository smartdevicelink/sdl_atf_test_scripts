---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is requested all capability in case HMI sends BC.GetSystemInfo notification with
-- incorrect data
--
-- Preconditions:
-- 1. hmi_capabilities_cache.json file doesn't exist on file system
-- 2. SDL and HMI are started
-- 3. HMI sends all HMI capabilities
-- 4. SDL stored capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 5. Ignition OFF/ON cycle performed
-- Sequence:
-- 5. HMI sends "BasicCommunication.GetSystemInfo" response without mandatory parameter "ccpu_version"/ invalid parameter type
--  a. sends all HMI capabilities request (VR/TTS/RC/UI etc)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local invalidTypeCcpuVersion = 1

--[[ Local Functions ]]
local function noRequestsGetHMIParams(pVersion)
  local hmiValues = common.noRequestsGetHMIParams()
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
common.Step("Ignition on, Start SDL, HMI sends GetSystemInfo notification with invalid parameter type",
  common.start, { common.updateHMISystemInfo(invalidTypeCcpuVersion) })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends the same cppu_version_1",
  common.start, { noRequestsGetHMIParams("cppu_version_1") })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, HMI sends GetSystemInfo notification without mandatory parameter ccpu_version",
  common.start, { common.updateHMISystemInfo() })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends the same cppu_version_1",
  common.start, { noRequestsGetHMIParams("cppu_version_1") })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

