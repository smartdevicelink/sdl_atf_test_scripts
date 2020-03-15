---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is compare saved ccpu_version parameter and received from HMI. In case ccpu_version value
-- different, SDL does requested all capability from HMI
--
-- Preconditions:
-- 1) Check that file with capability file doesn't exist on file system
-- 2) SDL and HMI are started
-- 3) HMI sends all capability to SDL
-- 4) SDL stored capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 5) Ignition OFF/ON cycle performed
-- 6) SDL is started
-- Steps:
-- 1) HMI sends "BasicCommunication.GetSystemInfo" notification with the same ccpu_version
-- SDL does:
-- - a) load capability from "hmi_capabilities_cache.json" file
-- - b) not send requests for all capability to SDL
-- 7) Ignition OFF/ON cycle performed
-- 8) SDL is started
-- Steps:
-- 2) HMI sends "BasicCommunication.GetSystemInfo" notification with the different ccpu_version
-- SDL does:
-- - a) send requested to HMI for all capability
-- - b) stored all capability to "hmi_capabilities_cache.json" file in AppStorageFolder
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Functions ]]
local function updateHMIValue()
  local hmiValues = common.getDefaultHMITable()
  hmiValues.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = "New_ccpu_version",
      language = "EN-US",
      wersCountryCode = "wersCountryCode"
    }
  }
  return hmiValues
end

local function getHMIParams()
  local params = common.getDefaultHMITable()
  params.RC.GetCapabilities.occurrence = 0
  params.UI.GetSupportedLanguages.occurrence = 0
  params.UI.GetCapabilities.occurrence = 0
  params.VR.GetSupportedLanguages.occurrence = 0
  params.VR.GetCapabilities.occurrence = 0
  params.TTS.GetSupportedLanguages.occurrence = 0
  params.TTS.GetCapabilities.occurrence = 0
  params.Buttons.GetCapabilities.occurrence = 0
  params.VehicleInfo.GetVehicleType.occurrence = 0
  params.UI.GetLanguage.occurrence = 0
  params.VR.GetLanguage.occurrence = 0
  params.TTS.GetLanguage.occurrence = 0
  return params
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment check HMICapabilitiesCacheFile", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends the same cppu_version", common.start, { getHMIParams() })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends different cppu_version", common.start, { updateHMIValue() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
