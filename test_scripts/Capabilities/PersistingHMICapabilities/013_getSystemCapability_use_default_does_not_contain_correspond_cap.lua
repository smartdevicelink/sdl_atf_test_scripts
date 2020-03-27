---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that the SDL takes default parameters from hmi_capabilities.json in case
-- HMI does not provide successful GetCapabilities/GetLanguage/GetVehicleType responses due to timeout

-- Preconditions:
-- 1) hmi_capabilities_cache.json file doesn't exist on file system
-- 2) HMI and SDL are started
-- Steps:
-- 1) HMI does not provide any Capability
-- SDL does:
--  a) use default capability from hmi_capabilities.json file
--  b) not persist default capabilities in cache file
-- 2) IGN_OFF/IGN_ON
-- SDL does:
--  a) cached of all capability
--  b) created HMICapabilitiesCache file with all capability on file system
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Functions ]]

local requests = {
  UI = { "GetCapabilities" },
  RC = { "GetCapabilities" }
}

local function hmiDefaultData()
  local path_to_file = config.pathToSDL .. "/hmi_capabilities.json"
  local defaultValue = common.jsonFileToTable(path_to_file)
  return defaultValue
end

local hmiCaps = common.getDefaultHMITable()

local function updateHMICaps(pMod, pRequest)
  for key,_ in pairs (hmiCaps) do
    if key == pMod then
      hmiCaps[pMod][pRequest] = nil
      if not pMod == "Buttons" then
        hmiCaps[pMod].IsReady.params.available = true
      end
    end
  end
end

--[[ Local Variables ]]
local hmiDefault = hmiDefaultData()

local function getSystemCapability(pSystemCapabilityType, pResponseCapabilities)
  local mobSession = common.getMobileSession()
  local cid = mobSession:SendRPC("GetSystemCapability", { systemCapabilityType = pSystemCapabilityType })
  mobSession:ExpectResponse(cid, { systemCapability = pResponseCapabilities, success = true, resultCode = "SUCCESS" })
end

local systemCapabilities = {
  UI = {
    NAVIGATION = { navigationCapability = hmiDefault.UI.systemCapabilities.navigationCapability },
    PHONE_CALL = { phoneCapability = hmiDefault.UI.systemCapabilities.phoneCapability },
    VIDEO_STREAMING = { videoStreamingCapability = hmiDefault.UI.systemCapabilities.videoStreamingCapability }},
  RC = {
    REMOTE_CONTROL = { remoteControlCapability = hmiDefault.RC.remoteControlCapability },
    SEAT_LOCATION = { remoteControlCapability = hmiDefault.RC.seatControlCapability }
  }
}

--[[ Scenario ]]

for mod, req  in pairs(requests) do
  for _, pReq  in ipairs(req) do
common.Title("TC processing " .. tostring(mod) .."]")
common.Title("Preconditions")
common.Step("Back-up/update PPT", common.updatePreloadedPT)
common.Step("Clean environment", common.preconditions)

common.Title("Test")

common.Step("Updated HMI Capabilities", updateHMICaps, { mod, pReq })
common.Step("Ignition on, Start SDL, HMI", common.start, { hmiCaps })
common.Step("App registration", common.registerApp)
common.Step("App activation", common.activateApp)
  for sysCapType, cap  in pairs(systemCapabilities[mod]) do
    common.Step("getSystemCapability "..sysCapType, getSystemCapability, { sysCapType, cap })
  end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
  end
end

