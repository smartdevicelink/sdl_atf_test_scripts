---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL persists all HMI Capabilities (VR/TTS/RC/UI/Buttons.GetCapabilities/,
--  VR/TTS/UI.GetSupportedLanguages/GetLanguage, VehicleInfo.GetVehicleType) received from HMI
--  in HMI capability cash file.
-- SDL does not send correspond HMI Capabilities (VR/TTS/RC/UI etc) request to HMI for subsequent ignition cycles.
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capability cash file (hmi_capabilities_cache.json) doesn't exist on file system
-- 3. SDL and HMI are started
-- Sequence:
-- 1. HMI responds with available = true on VR/TTS/RC/UI/VehicleInfo.IsReady requests from SDL
--   a. SDL sends HMI capabilities (VR/TTS/RC/UI etc) requests to HMI
-- 2. HMI sends all HMI capabilities (VR/TTS/RC/UI/Buttons/VehicleInfo etc) responses
--   a. SDL persists all HMI Capabilities to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 3. Ignition OFF/ON cycle performed
--   a. SDL does not send HMI capabilities (VR/TTS/RC/UI etc) requests to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Start SDL and HMI, SDL sends HMI capabilities requests to HMI", common.start)
common.Step("Validate stored capability file", common.checkContentOfCapabilityCacheFile)
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, SDL doesn't send HMI capabilities requests to HMI",
  common.start, { common.noRequestsGetHMIParams() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
