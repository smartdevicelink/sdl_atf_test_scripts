---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is create file, save capability to file and loading capability form file after ignition
-- OFF/ON cycle
--
-- Preconditions:
-- 1) Check that file with capability file doesn't exist on file system
-- 2) SDL and HMI are started
-- Steps:
-- 1) HMI sends "BasicCommunication.OnReady" notification
-- SDL does:
-- - a) request all capability from HMI
-- Steps:
-- 2) HMI sends all capability to SDL
-- SDL does:
-- - a) stored all capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 3) Ignition OFF/ON cycle performed
-- Steps:
-- 3) SDL is started
-- SDL does:
-- - a) check if hmi_capabilities_cache.json file present in AppStorageFolder
-- - b) check that all mandatory capability preset
-- - c) load capability from "hmi_capabilities_cache.json" file
-- - d) not send requests for all capability to SDL
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Functions ]]
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
common.Step("Clean environment", common.precondition)
common.Step("Check that capability file doesn't exist", common.checkIfDoesNotExistCapabilityFile)

common.Title("Test")
common.Step("Start SDL and HMI", common.start)
common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI", common.start, { getHMIParams() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
