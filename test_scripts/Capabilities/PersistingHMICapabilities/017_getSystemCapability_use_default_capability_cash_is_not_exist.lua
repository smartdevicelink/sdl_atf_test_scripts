---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that the SDL use default capabilities from hmi_capabilities.json in case
-- HMI does not send successful GetCapabilities/GetLanguage/GetVehicleType responses due to timeout

-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file (hmi_capabilities_cache.json) doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI does not provide all HMI capabilities (VR/TTS/RC/UI etc)
-- Sequence:
-- 1. App sends "GetSystemCapability" request
--  a. SDL sends "GetSystemCapability" response with correspondent capabilities stored in hmi_capabilities.json
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local hmiCapabilities = common.getHMICapabilitiesFromFile()

local systemCapabilities = {
  NAVIGATION = { navigationCapability = hmiCapabilities.UI.systemCapabilities.navigationCapability },
  PHONE_CALL = { phoneCapability = hmiCapabilities.UI.systemCapabilities.phoneCapability },
  VIDEO_STREAMING = { videoStreamingCapability = hmiCapabilities.UI.systemCapabilities.videoStreamingCapability },
  REMOTE_CONTROL = { remoteControlCapability = hmiCapabilities.RC.remoteControlCapability },
  SEAT_LOCATION = { seatLocationCapability = hmiCapabilities.RC.seatLocationCapability }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Ignition on, Start SDL, HMI", common.start, { common.getHMIParamsWithOutResponse() })
common.Step("Check that capabilities file doesn't exist", common.checkIfCapabilityCacheFileExists, { false })
common.Step("App registration", common.registerApp)
common.Step("App activation", common.activateApp)
for sysCapType, cap  in pairs(systemCapabilities) do
  common.Title("TC processing " .. tostring(sysCapType) .. "]")
  common.Step("getSystemCapability ".. sysCapType, common.getSystemCapability, { sysCapType, cap })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
