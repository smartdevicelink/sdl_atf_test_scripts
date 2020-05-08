---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL suspend of RAI request processing from mobile app until all HMI Capabilities
--  (VR/TTS/RC/UI/Buttons.GetCapabilities/,VR/TTS/UI.GetSupportedLanguages/GetLanguage, VehicleInfo.GetVehicleType)
--  are received from HMI in case HMI capabilities cache file is undefined in smartDeviceLink.ini file
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is undefined in smartDeviceLink.ini file
-- 2. HMI capabilities cache file doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI sends all HMI capabilities (VR/TTS/RC/UI etc) to SDL
-- 5. Local ccpu_version matches with received ccpu_version from HMI
-- Sequence:
-- 1. Mobile sends RegisterAppInterface request to SDL
--  a. SDL suspend of RAI request processing from mobile
-- 2. HMI sends all HMI capabilities (VR/TTS/RC/UI etc) to SDL
--  a. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local appSessionId = 1
local ccpuVersion = "cppu_version_1"

--[[ Local Functions ]]
local function getHMIParamsWithOutResponse(pVersion)
  local hmiValues = common.getHMIParamsWithOutResponse()
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
common.Step("Update HMICapabilitiesCacheFile in SDL.ini file ", common.setSDLIniParameter,
  { "HMICapabilitiesCacheFile", "" })
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile)
common.Step("Start SDL, HMI", common.start, { getHMIParamsWithOutResponse(ccpuVersion) })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI", common.startWoHMIonReady)
common.Step("Check suspending App registration", common.registerAppSuspend,
  { appSessionId, common.buildCapRaiResponse(), common.updateHMISystemInfo(ccpuVersion) })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
