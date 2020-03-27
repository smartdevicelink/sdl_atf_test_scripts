---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that the SDL takes default parameters from hmi_capabilities.json in case
-- HMI does not provide successful GetCapabilities/GetLanguage/GetVehicleType response due to timeout

-- Preconditions:
-- 1) hmi_capabilities_cache.json file doesn't exist on file system
-- 2) HMI and SDL are started
-- Steps:
-- 1) HMI does not provide one of available Capability
-- SDL does:
--  a) use appropriate default capability from hmi_capabilities.json file
--  b) not persist appropriate default capabilities in cache file
-- 2) IGN_OFF/IGN_ON
-- SDL does:
--  a) cached of all capability
--  b) created HMICapabilitiesCache file with all capability on file system
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

local requests = {
  UI = { "GetCapabilities", "GetLanguage" },
  VR = { "GetCapabilities", "GetLanguage" },
  TTS = { "GetCapabilities", "GetLanguage" },
  Buttons = { "GetCapabilities" },
  VehicleInfo = { "GetVehicleType" }
}

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

local function hmiDefaultData()
  local path_to_file = config.pathToSDL .. "/hmi_capabilities.json"
  local defaulValue = common.jsonFileToTable(path_to_file)
  return defaulValue
end

local function changeBitsPSEnumPcmCap(pCapabilities)
  local bitsPerSampleEnum = common.cloneTable(pCapabilities)
  for pKey, value in pairs(bitsPerSampleEnum) do
    if pKey == "bitsPerSample" then
      bitsPerSampleEnum.bitsPerSample = string.gsub(value, "RATE_", "")
    end
  end
  return bitsPerSampleEnum
end

local function changeBitsPSEnumAudioCap(pCapabilities)
  local bitsPerSampleEnum = common.cloneTable(pCapabilities)
  for _, value in ipairs(bitsPerSampleEnum) do
    for pKey, pValue in pairs(value) do
      if pKey == "bitsPerSample" then
        value.bitsPerSample = string.gsub(pValue, "RATE_", "")
      end
    end
  end
  return bitsPerSampleEnum
end


--[[ Local Variables ]]
local hmiDefault = hmiDefaultData()


local function del()
  hmiDefault.UI.displayCapabilities.imageCapabilities = nil  -- no Mobile_API.xml
  hmiDefault.UI.displayCapabilities.menuLayoutsAvailable = nil --since 6.0
  return hmiDefault.UI.displayCapabilities
end



local capRaiResponse = {
  UI = {
    GetCapabilities = {
      audioPassThruCapabilities = changeBitsPSEnumAudioCap(hmiDefault.UI.audioPassThruCapabilities),
      pcmStreamCapabilities = changeBitsPSEnumPcmCap(hmiDefault.UI.pcmStreamCapabilities),
      hmiZoneCapabilitie = hmiDefault.UI.hmiZoneCapabilitie,
      softButtonCapabilities = hmiDefault.UI.softButtonCapabilities,
      displayCapabilities = del(),
    },
    GetLanguage = {
      hmiDisplayLanguage =  hmiDefault.UI.language }},
  VR = {
    GetCapabilities = {
      vrCapabilities = hmiDefault.VR.capabilities },
    GetLanguage = {
      language = hmiDefault.VR.language,}},
  TTS = {
    GetCapabilities = {
      speechCapabilities = hmiDefault.TTS.capabilities },
    GetLanguage = {
      language = hmiDefault.TTS.language}},
  Buttons = {
    GetCapabilities = {
      buttonCapabilities = hmiDefault.Buttons.capabilities }},
  VehicleInfo = {
    GetVehicleType  = {
      vehicleType = hmiDefault.VehicleInfo.vehicleType }}
}


--[[ Scenario ]]
for mod, req  in pairs(requests) do
  for _, pReq  in ipairs(req) do

common.Title("Preconditions")
common.Title("TC processing " .. tostring(mod) .." " .. tostring(pReq).."]")

common.Step("Clean environment", common.preconditions)

common.Title("Test")
common.Step("Updated HMI Capabilities", updateHMICaps, { mod, pReq })
common.Step("Ignition on, Start SDL, HMI", common.start, { hmiCaps })
common.Step("App registration", common.registerApp, { 1, capRaiResponse[mod][pReq] })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

  end
end
