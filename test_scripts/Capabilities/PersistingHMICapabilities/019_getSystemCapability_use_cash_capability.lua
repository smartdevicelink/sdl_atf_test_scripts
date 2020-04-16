---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL use capabilities from stored in hmi_capabilities_cache.json
-- SDL sends GetSystemCapability response with all capabilities stored in hmi_capabilities_cache.json
--  on GetSystemCapability(NAVIGATION/PHONE_CALL/VIDEO_STREAMING/REMOTE_CONTROL/SEAT_LOCATION) request from Mobile App
--
-- Preconditions:
-- 1. Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capability cash file (hmi_capabilities_cache.json) exists on file system
-- 3. All HMI Capabilities (VR/TTS/RC/UI etc) are presented in hmi_capabilities_cache.json
-- 4. SDL and HMI are started
-- 5. App is registered
-- Sequence:
-- 1. App sends "GetSystemCapability" request
--  a. SDL sends "GetSystemCapability" response with correspondent capabilities stored in hmi_capabilities_cache.json
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local hmiCap = common.getDefaultHMITable()

local systemCapabilities = {
  NAVIGATION = {
    navigationCapability = hmiCap.UI.GetCapabilities.params.systemCapabilities.navigationCapability },
  PHONE_CALL = {
    phoneCapability = hmiCap.UI.GetCapabilities.params.systemCapabilities.phoneCapability },
  VIDEO_STREAMING = {
    videoStreamingCapability = hmiCap.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability },
  REMOTE_CONTROL = {
    remoteControlCapability = hmiCap.RC.GetCapabilities.params.remoteControlCapability },
  SEAT_LOCATION = {
    seatLocationCapability = hmiCap.RC.GetCapabilities.params.seatLocationCapability }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update HMI capabilities", common.updatedHMICapabilitiesFile)

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI", common.start)
common.Step("Check that capability file exists", common.checkIfCapabilityCashFileExists)
common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI", common.start, { common.noRequestsGetHMIParams() })
common.Step("App registration", common.registerApp)
common.Step("App activation", common.activateApp)

for sysCapType, cap  in pairs(systemCapabilities) do
  common.Title("TC processing " .. tostring(sysCapType) .. "]")
  common.Step("getSystemCapability " .. sysCapType, common.getSystemCapability, { sysCapType, cap })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
