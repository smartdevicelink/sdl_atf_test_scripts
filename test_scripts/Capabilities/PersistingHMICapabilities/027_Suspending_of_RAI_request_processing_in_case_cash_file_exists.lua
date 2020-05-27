---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL does not suspend of RAI request processing from mobile app in case HMI capabilities cache file
-- exists on file system and ccpu_version matches with received ccpu_version from HMI
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
-- 3. HMI sends all capabilities to SDL
-- 4. SDL persists capabilities to HMI capabilities cache file ("hmi_capabilities_cache.json") in AppStorageFolderr
-- 5. Ignition OFF/ON cycle performed
-- 6. SDL is started and send GetSystemInfo request
-- Sequence:
-- 1. Mobile sends RegisterAppInterface request to SDL
--  a. SDL suspends of RAI request processing from mobile
-- 2. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
--   SDL does not send HMI capabilities (VR/TTS/RC/UI etc) requests to HMI
--   SDL sends RegisterAppInterface response with corresponding capabilities (stored in hmi_capabilities_cache.json)
--   to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Test Configuration ]]
common.checkDefaultMobileAdapterType({ "TCP" })

--[[ Local Variables ]]
local appSessionId = 1
local ccpuVersion = "cppu_version_1"

--[[ Local Functions ]]
local function getHMIParamsWithOutRequests(pVersion)
  local hmiValues = common.getHMIParamsWithOutRequests()
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
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile)
common.Step("Start SDL, HMI", common.start, { common.updateHMISystemInfo(ccpuVersion) })
common.Step("Ignition off", common.ignitionOff)

common.Title("Test")
common.Step("Start SDL, HMI", common.startWoHMIonReady )
common.Step("Check suspending App registration", common.registerAppSuspend,
  { appSessionId, common.buildCapRaiResponse(), getHMIParamsWithOutRequests(ccpuVersion) })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
