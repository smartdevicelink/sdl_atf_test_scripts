---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: SDL does not send all HMI Capabilities (VR/TTS/RC/UI etc) requests to HMI for subsequent ignition cycles
--  in case HMI sends BC.GetSystemInfo response with another language/wersCountryCode
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1", language = "EN-US",
--   wersCountryCode = "wersCountryCode_1" to SDL
-- 3. HMI sends all HMI capabilities (VR/TTS/RC/UI etc)
-- 4. SDL persists capabilities to HMI capabilities cache file ("hmi_capabilities_cache.json") in AppStorageFolder
-- 5. Ignition OFF/ON cycle performed
-- 6. SDL is started and send GetSystemInfo request
-- Sequence:
-- 1. HMI sends GetSystemInfo with another language = "FR-FR" to SDL
--   a) SDL does not send requests for any HMI capabilities (VR/TTS/RC/UI etc) to HMI
-- 2. Ignition OFF/ON cycle performed
-- 3. HMI sends GetSystemInfo with another wersCountryCode = wersCountryCode_2 to SDL
--   a) SDL does not send requests for any HMI capabilities (VR/TTS/RC/UI etc) to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local ccpuVersion = "cppu_version_1"
local defaultHMIParams = common.getDefaultHMITable()
local HMIParamsWithOutRequests = common.getHMIParamsWithOutRequests()

--[[ Local Functions ]]
local function updateHMIParams(pHMIParams, pVersion, pLanguage, pWersCountryCode)
  local hmiValues = pHMIParams
  hmiValues.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = pVersion,
      language = pLanguage,
      wersCountryCode = pWersCountryCode
    }
  }
  return hmiValues
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start,
  { updateHMIParams(defaultHMIParams, ccpuVersion, "EN-US", "wersCountryCode_1") })

common.Title("Test")
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends GetSystemInfo with another language ",
  common.start, { updateHMIParams(HMIParamsWithOutRequests, ccpuVersion, "FR-FR", "wersCountryCode_1") })
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI sends GetSystemInfo with another wersCountryCode ",
  common.start, { updateHMIParams(HMIParamsWithOutRequests, ccpuVersion, "FR-FR", "wersCountryCode_2") })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
