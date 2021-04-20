---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Check that SDL does not suspend of multiple RAI requests processing from mobile apps in case HMI capabilities cache file
--  exists on file system and ccpu_version matches with received ccpu_version from HMI
--
-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
-- 3. HMI sends all capabilities to SDL
-- 4. SDL persists capabilities to HMI capabilities cache file ("hmi_capabilities_cache.json") in AppStorageFolder
-- 5. Ignition OFF/ON cycle performed
-- 6. SDL is started and sends GetSystemInfo request
-- Sequence:
-- 1. Mobile App1 sends RegisterAppInterface request from Mobile device1 to SDL
--  a. SDL suspends of RAI request processing from mobile
-- 2. Mobile App2 sends RegisterAppInterface request from Mobile device1 to SDL
--  a. SDL suspends of RAI request processing from mobile
-- 3. Mobile App3 sends RegisterAppInterface request from Mobile device2 to SDL
--  a. SDL suspends of RAI requests processing from mobile
-- 4. HMI sends GetSystemInfo with ccpu_version = "ccpu_version_1" to SDL
--   SDL does not send HMI capabilities (VR/TTS/RC/UI etc) requests to HMI
--   a. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile App1
--   b. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile App2
--   c. SDL sends RegisterAppInterface response with corresponding capabilities received from HMI to Mobile App3
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Test Configuration ]]
common.checkDefaultMobileAdapterType({ "TCP" })

--[[ Local Variables ]]
local anotherDeviceParams = { host = "1.0.0.1", port = config.mobilePort }
local appSessionId1 = 1
local appSessionId2 = 2
local appSessionId3 = 3
local mobConnId1 = 1
local mobConnId2 = 2
local ccpuVersion = "cppu_version_1"

--[[ Local Functions ]]
local function getHMIParamsWithOutRequests(pVersion)
  return common.getHMIParamsWithOutRequests(common.updateHMISystemInfo(pVersion))
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updateHMICapabilitiesFile)
common.Step("Start SDL, HMI", common.start, { common.updateHMISystemInfo(ccpuVersion) })
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect default device 1", common.startWoHMIonReady)
common.Step("Connect another mobile device 2 (Mobile 2)", common.connectMobDevice, { mobConnId2, anotherDeviceParams})
common.Step("Start services App1 on mobile device 1", common.startService, { appSessionId1, mobConnId1 })
common.Step("Start services App2 on mobile device 1", common.startService, { appSessionId2, mobConnId1 })
common.Step("Start services App3 on mobile device 2", common.startService, { appSessionId3, mobConnId2 })

common.Title("Test")
common.Step("Check suspending multiple Apps registration", common.registerAppsSuspend,
  { common.buildCapRaiResponse(), getHMIParamsWithOutRequests(ccpuVersion) })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
