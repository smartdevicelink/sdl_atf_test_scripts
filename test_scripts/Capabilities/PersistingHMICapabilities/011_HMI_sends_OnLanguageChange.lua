---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that SDL is update "hmi_capabilities_cache.json" file during receiving dynamic capability from HMI
-- OFF/ON cycle
--
-- Preconditions:
-- 1) Check that file with capability file doesn't exist on file system
-- 2) SDL and HMI are started
-- 3) HMI sends all capability to SDL
-- 4) SDL stored capability to "hmi_capabilities_cache.json" file in AppStorageFolder
-- 5) App is registered and activated
-- Steps:
-- 1) HMI sends "TTS.OnLanguageChange" and "VR.OnLanguageChange" notifications to SDL
-- SDL does:
-- - a) send "OnLanguageChange" and "OnAppInterfaceUnregistered" notifications to App
-- - b) updated new capability in "hmi_capabilities_cache.json" file
-- 6) Ignition OFF/ON cycle performed
-- Steps:
-- 2) SDL is started
-- SDL does:
-- - a) check if hmi_capabilities_cache.json file present in AppStorageFolder
-- - b) load capability from "hmi_capabilities_cache.json" file
-- - c) not send requests for all capability to SDL
-- 7) App is registered and activated
-- Steps:
-- 3) HMI sends "TTS.OnLanguageChange" and "VR.OnLanguageChange" notifications to SDL
-- SDL does:
-- - a) send "OnLanguageChange" and "OnAppInterfaceUnregistered" notifications to App
-- - b) updated new capability in "hmi_capabilities_cache.json" file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')
local HMICacheFile_pathToFile = config.pathToSDL .. "storage/"

--[[ Local Functions ]]
local function getHMIParams()
  local params = common.getDefaultHMITable()
  params.RC.GetCapabilities.occurrence = 0
  params.UI.GetSupportedLanguages.occurrence = 0
  params.UI.GetCapabilities.occurrence = 0
  params.VR.GetSupportedLanguages.occurrence = 0
  params.VR.GetCapabilities.occurrence = 0
  params.TTS.GetSupportedLanguages.occurrence = 0
  params.TTS.GetCapabilities.occurrence = 0
  params.Buttons.GetCapabilities.occurrence = 0
  params.VehicleInfo.GetVehicleType.occurrence = 0
  params.UI.GetLanguage.occurrence = 0
  params.VR.GetLanguage.occurrence = 0
  params.TTS.GetLanguage.occurrence = 0
  return params
end

local function checkLanguageCapability(pLanguage)
  local file = io.open(HMICacheFile_pathToFile.. "hmi_capabilities_cache.json", "r")
  local json_data = file:read("*a")
  file:close()
  local data = common.decode(json_data)
  if data.VR.language == pLanguage and data.TTS.language == pLanguage then
    common.print(35, "Languages was changed")
  else
    common.print(35, "SDL doesn't updated cache file")
  end
end

local function onLanguageChange(pLanguage, pAppID)
  common.hmi.getConnection():SendNotification("TTS.OnLanguageChange", { language = pLanguage })
  common.hmi.getConnection():SendNotification("VR.OnLanguageChange", { language = pLanguage })
  if pAppID then
    common.getMobileSession():ExpectNotification("OnLanguageChange", { language = pLanguage })
    common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "LANGUAGE_CHANGE" })
  end
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment check HMICapabilitiesCacheFile", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("Validate stored capability file", common.checkContentCapabilityCacheFile)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("OnLanguageChange notification", onLanguageChange, { "FR-FR", 1 })
common.Step("Check stored value to cache file", checkLanguageCapability, { "FR-FR" })

common.Step("Ignition off", common.ignitionOff)
common.Step("Ignition on, Start SDL, HMI", common.start, { getHMIParams() })

common.Step("OnLanguageChange notification", onLanguageChange, { "EN-EN" })
common.Step("Check stored value to cache file", checkLanguageCapability, { "EN-EN" })
common.Step("Register App", common.registerAppWOPTU)

common.Step("OnLanguageChange", onLanguageChange, { "DE-DE", 1 })
common.Step("Check stored value to cache file", checkLanguageCapability, { "DE-DE" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
