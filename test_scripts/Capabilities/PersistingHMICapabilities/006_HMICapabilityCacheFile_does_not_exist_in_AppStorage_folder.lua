---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL sends appropriate HMI capabilities request (VR/TTS/RC/UI etc)
--  in case one of them is missing in "hmi_capabilities_cache.json" file
--
-- Preconditions:
-- 1) hmi_capabilities_cache.json file doesn't exist on file system
-- 2) SDL and HMI are started
-- 3) HMI does not provide one of HMI capability
-- Steps:
-- 1) IGN_OFF/IGN_ON
-- SDL does:
--  a) sends appropriate HMI capability request
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
local function updateHMICaps_noResponseGetHMIParam(pMod, pReq)
  local noResponseGetHMIParam = common.cloneTable(hmiDefaultCap)
  noResponseGetHMIParam[pMod][pReq] = nil
  return noResponseGetHMIParam
end

local function updateHMICaps_requestGetHMIParam(pMod, pReq)
  local requestGetHMIParam = common.cloneTable(hmiDefaultCap)
  requestGetHMIParam.UI.GetLanguage.occurrence = 0
  requestGetHMIParam.UI.GetSupportedLanguages.occurrence = 0
  requestGetHMIParam.UI.GetCapabilities.occurrence = 0
  requestGetHMIParam.VR.GetLanguage.occurrence = 0
  requestGetHMIParam.VR.GetSupportedLanguages.occurrence = 0
  requestGetHMIParam.VR.GetCapabilities.occurrence = 0
  requestGetHMIParam.TTS.GetLanguage.occurrence = 0
  requestGetHMIParam.TTS.GetSupportedLanguages.occurrence = 0
  requestGetHMIParam.TTS.GetCapabilities.occurrence = 0
  requestGetHMIParam.Buttons.GetCapabilities.occurrence = 0
  requestGetHMIParam.VehicleInfo.GetVehicleType.occurrence = 0
  requestGetHMIParam.RC.GetCapabilities.occurrence = 0
  requestGetHMIParam[pMod][pReq].occurrence = nil
  return requestGetHMIParam
end

--[[ Scenario ]]
for mod, req  in pairs(cap) do
  for _, pReq  in ipairs(req) do
    common.Title("Preconditions")
    common.Step("Clean environment", common.preconditions)
    common.Step("Start SDL,HMI does not provide capability on request "..mod .."." ..pReq,
      common.start, { updateHMICaps_noResponseGetHMIParam(mod, pReq) })
    common.Step("Ignition off", common.ignitionOff)

    common.Title("Test")
    common.Step("Ignition on, SDL doesn't send " ..mod .."." ..pReq .." request",
      common.start, { updateHMICaps_requestGetHMIParam (mod, pReq) })

    common.Title("Postconditions")
    common.Step("Stop SDL", common.postconditions)
  end
end
