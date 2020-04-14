---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL use capabilities stored in hmi_capabilities_cache.json
--  SDL sends RegisterAppInterface response with all capabilities stored in hmi_capabilities_cache.json
-- on RegisterAppInterface request from Mobile App

-- Preconditions:
-- 1. Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capability cash file (hmi_capabilities_cache.json) exists on file system
-- 3. All HMI Capabilities (VR/TTS/RC/UI etc) are presented in hmi_capabilities_cache.json
-- 4. SDL and HMI are started
-- Sequence:
-- 1. Mobile sends RegisterAppInterface request to SDL
--  a. SDL sends RegisterAppInterface response with correspond capabilities (stored in hmi_capabilities_cache.json) to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local hmiCapabilities = common.getDefaultHMITable()

local capRaiResponse = {
  buttonCapabilities = hmiCapabilities.Buttons.GetCapabilities.params.capabilities,
  vehicleType = hmiCapabilities.VehicleInfo.GetVehicleType.params.vehicleType,
  audioPassThruCapabilities = hmiCapabilities.UI.GetCapabilities.params.audioPassThruCapabilitiesList,
  hmiDisplayLanguage =  hmiCapabilities.UI.GetCapabilities.params.language,
  language = hmiCapabilities.VR.GetLanguage.params.language, -- or TTS.language
  pcmStreamCapabilities = hmiCapabilities.UI.GetCapabilities.params.pcmStreamCapabilities,
  hmiZoneCapabilities = hmiCapabilities.UI.GetCapabilities.params.hmiZoneCapabilities,
  softButtonCapabilities = hmiCapabilities.UI.GetCapabilities.params.softButtonCapabilities,
  displayCapabilities = hmiCapabilities.UI.GetCapabilities.params.displayCapabilities,
  vrCapabilities = hmiCapabilities.VR.GetCapabilities.params.capabilities,
  speechCapabilities = hmiCapabilities.TTS.GetCapabilities.params.capabilities
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updatedHMICapabilitiesFile)

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI", common.start)
common.Step("Check that capability file exists", common.checkIfCapabilityCashFileExists)
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, HMI, SDL doesn't send HMI capabilities requests to HMI",
  common.start, { common.noRequestsGetHMIParams() })
common.Step("App registration", common.registerApp, { appSessionId, capRaiResponse })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
