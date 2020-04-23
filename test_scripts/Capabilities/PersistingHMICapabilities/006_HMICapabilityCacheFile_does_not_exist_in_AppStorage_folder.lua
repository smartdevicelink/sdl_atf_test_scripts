---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL sends correspondent HMI capabilities request (VR/TTS/RC/UI/Buttons/VehicleInfo etc)
--  in case one of them is missing in HMI capability cache ("hmi_capabilities_cache.json") file
--
-- Preconditions:
-- 1. Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. hmi_capabilities_cache.json doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI does not provide one of HMI capabilities (VR/TTS/RC/UI/Buttons/VehicleInfo etc)
-- Sequence:
-- 1. IGN_OFF/IGN_ON
--  a. SDL sends correspondent HMI capabilities (VR/TTS/RC/UI/Buttons/VehicleInfo etc) request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variable ]]
local hmiDefaultCap = common.getDefaultHMITable()

local cap = {
  UI = { "GetLanguage", "GetSupportedLanguages", "GetCapabilities" },
  VR = { "GetLanguage", "GetSupportedLanguages", "GetCapabilities" },
  TTS = { "GetLanguage", "GetSupportedLanguages", "GetCapabilities" },
  Buttons = { "GetCapabilities" },
  VehicleInfo = { "GetVehicleType" },
  RC = { "GetCapabilities" }
}

--[[ Local Functions ]]
local function updateHMICaps_noResponseGetHMIParams(pMod, pReq)
  local noResponseGetHMIParams = common.cloneTable(hmiDefaultCap)
  noResponseGetHMIParams[pMod][pReq] = nil
  return noResponseGetHMIParams
end

local function updateHMICaps_requestGetHMIParams(pMod, pReq)
  local requestGetHMIParams = common.cloneTable(hmiDefaultCap)
  requestGetHMIParams.UI.GetLanguage.occurrence = 0
  requestGetHMIParams.UI.GetSupportedLanguages.occurrence = 0
  requestGetHMIParams.UI.GetCapabilities.occurrence = 0
  requestGetHMIParams.VR.GetLanguage.occurrence = 0
  requestGetHMIParams.VR.GetSupportedLanguages.occurrence = 0
  requestGetHMIParams.VR.GetCapabilities.occurrence = 0
  requestGetHMIParams.TTS.GetLanguage.occurrence = 0
  requestGetHMIParams.TTS.GetSupportedLanguages.occurrence = 0
  requestGetHMIParams.TTS.GetCapabilities.occurrence = 0
  requestGetHMIParams.Buttons.GetCapabilities.occurrence = 0
  requestGetHMIParams.VehicleInfo.GetVehicleType.occurrence = 0
  requestGetHMIParams.RC.GetCapabilities.occurrence = 0
  requestGetHMIParams[pMod][pReq].occurrence = nil
  return requestGetHMIParams
end

--[[ Scenario ]]
for mod, req  in pairs(cap) do
  for _, pReq  in ipairs(req) do
    common.Title("Preconditions")
    common.Step("Clean environment", common.preconditions)
    common.Step("Start SDL, HMI does not provide capability on request " .. mod .. "." .. pReq,
      common.start, { updateHMICaps_noResponseGetHMIParams(mod, pReq) })
    common.Step("Ignition off", common.ignitionOff)

    common.Title("Test")
    common.Step("Ignition on, SDL doesn't send " .. mod .. "." .. pReq .." request",
      common.start, { updateHMICaps_requestGetHMIParams(mod, pReq) })

    common.Title("Postconditions")
    common.Step("Stop SDL", common.postconditions)
  end
end
