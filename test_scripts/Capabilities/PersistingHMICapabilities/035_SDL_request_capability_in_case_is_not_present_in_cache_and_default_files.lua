---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that the SDL sends appropriate HMI capabilities (VR/TTS/RC/UI/Buttons/VehicleInfo etc) request
--  to HMI in case they are not present in the HMI capabilities cache file (hmi_capabilities_cache.json) and
--  the default capabilities
--
-- Preconditions:
-- 1. Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capabilities cache file (hmi_capabilities_cache.json) exists on file system and does not contain
--   one of HMI capabilities ("absent capability")
-- 3. "Absent capability" is missing in HMICapabilities file (stored in hmi_capabilities.json)
-- Sequence
-- 1. SDL and HMI are started
--  a. SDL sends appropriate HMI capabilities request to HMI to receive "Absent capability"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variables ]]
local capabilitiesMap = {
  UI = {
    GetLanguage = { "language" },
    GetSupportedLanguages = { "languages" },
    GetCapabilities = { "displayCapabilities" }
    },
  VR = {
    GetLanguage = { "language" },
    GetSupportedLanguages = { "languages" },
    GetCapabilities = { "vrCapabilities" }
    },
  TTS = {
    GetLanguage = { "language" },
    GetSupportedLanguages = { "languages" },
    GetCapabilities = { "speechCapabilities" }
    },
  Buttons = {
    GetCapabilities = { "capabilities" }
  },
  VehicleInfo = {
    GetVehicleType = { "vehicleType" }
  },
  RC = {
    GetCapabilities = { "remoteControlCapability" }
  }
}

--[[ Local Functions ]]
local function updateHMICaps(pMod, pRequest, pCap)
  local hmiCap = common.getDefaultHMITable()
  hmiCap[pMod][pRequest].params[pCap] = nil
  for mod, _ in pairs (hmiCap) do
    if not mod == "Buttons" then
      hmiCap[mod].IsReady.params.available = true
    end
  end
  return hmiCap
end

local function updateHMICapabilitiesFile(pMod, pCap)
  local hmiCapTbl = common.getHMICapabilitiesFromFile()
  hmiCapTbl[pMod][pCap] = nil
  common.setHMICapabilitiesToFile(hmiCapTbl)
end

local function getHMIParams(pMod, pRequest)
  local hmiCapTbl = common.getHMIParamsWithOutRequests()
  hmiCapTbl[pMod][pRequest].occurrence = 1
  return hmiCapTbl
end

--[[ Scenario ]]
for mod, capRequests  in pairs(capabilitiesMap) do
  for req, capabilities  in pairs(capRequests) do
    for _, cap  in ipairs(capabilities) do
      common.Title("Preconditions")
      common.Title("TC processing " .. tostring(mod) .. " " .. tostring(req) .. " " .. tostring(cap) .. "]")
      common.Step("Clean environment", common.preconditions)
      common.Step("Update HMI capabilities default", updateHMICapabilitiesFile, { mod, cap })
      common.Step("Ignition on, Start SDL, HMI", common.start, { updateHMICaps(mod, req, cap) })
      common.Step("Ignition off", common.ignitionOff)

      common.Title("Test")
      common.Step("Ignition on, Start SDL, HMI", common.start, { getHMIParams(mod, req) })

      common.Title("Postconditions")
      common.Step("Stop SDL", common.postconditions)
    end
  end
end
