---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL sends request for capability to HMI in case "hmi_capabilities_cache.json" file doesn't
-- contain all mandatory capability
--
-- Preconditions:
-- 1) Check that file with capability file doesn't exist on file system
-- 2) SDL and HMI are started
-- 3) HMI sends all capability to SDL
-- 4) SDL stored capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 5) HMI sends IGNITION_OFF
-- 6) Remove one of mandatory capability from Cache file
-- 7) Ignition ON
-- Steps:
-- 1) SDL is started
-- SDL does:
-- - a) check if hmi_capabilities_cache.json file present in AppStorageFolder
-- - b) check that all mandatory capability preset
-- Steps:
-- 2) File doesn't have one of mandatory capability
-- SDL does:
-- - a) send requested to HMI only for absented capability
-- Steps:
-- 3) HMI send response for absented capability
-- SDL does:
-- - a) stored absented capability to cache file
-- - b) not send request for existed capability
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')

--[[ Local Variable ]]
local cap = {
  UI = { "GetLanguage", "GetSupportedLanguages", "GetCapabilities" },
  VR = { "GetLanguage", "GetSupportedLanguages", "GetCapabilities" },
  TTS = { "GetLanguage", "GetSupportedLanguages", "GetCapabilities" },
  Buttons = { "GetCapabilities" },
  VehicleInfo = { "GetVehicleType" },
  RC = { "GetCapabilities" }
}

--[[ Local Functions ]]
local function getHMIParams(pMod, pReq)
  local params = common.getDefaultHMITable()
  local tbl =  common.cloneTable(params)
  tbl.UI.GetLanguage.occurrence = 0
  tbl.UI.GetSupportedLanguages.occurrence = 0
  tbl.UI.GetCapabilities.occurrence = 0
  tbl.VR.GetLanguage.occurrence = 0
  tbl.VR.GetSupportedLanguages.occurrence = 0
  tbl.VR.GetCapabilities.occurrence = 0
  tbl.TTS.GetLanguage.occurrence = 0
  tbl.TTS.GetSupportedLanguages.occurrence = 0
  tbl.TTS.GetCapabilities.occurrence = 0
  tbl.Buttons.GetCapabilities.occurrence = 0
  tbl.VehicleInfo.GetVehicleType.occurrence = 0
  tbl.RC.GetCapabilities.occurrence = 0
  tbl[pMod][pReq].occurrence = nil
  return tbl
end

--[[ Scenario ]]
for mod, req  in pairs(cap) do
  for _, pReq  in ipairs(req) do
    common.Title("Preconditions")
    common.Step("Clean environment check HMICapabilitiesCacheFile", common.precondition)
    common.Step("Start SDL, HMI", common.start)
    common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)
    common.Step("Ignition off", common.ignitionOff)

    common.Title("Test")
    common.Step("Remove " .. mod .. pReq .. " capability from Cache file", common.updateCacheFile, { mod, pReq })
    common.Step("Ignition on, expect" .. mod .. pReq .. " request capability from SDL",
      common.start, { getHMIParams(mod, pReq) })

    common.Title("Postconditions")
    common.Step("Stop SDL", common.postconditions)
  end
end
