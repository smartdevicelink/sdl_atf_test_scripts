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
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local appSessionId = 1
local hmiDefaultCap = common.getDefaultHMITable()
local hmiCapabilities = common.getHMICapabilitiesFromFile()

local requests = {
  UI = { "GetCapabilities", "GetLanguage" },
  VR = { "GetCapabilities", "GetLanguage" },
  TTS = { "GetCapabilities", "GetLanguage" },
  Buttons = { "GetCapabilities" },
  VehicleInfo = { "GetVehicleType" }
}

--[[ Local Functions ]]
local function updateHMICaps(pMod, pRequest)
  for key,_ in pairs (hmiDefaultCap) do
    if key == pMod then
      hmiDefaultCap[pMod][pRequest] = nil
      if not pMod == "Buttons" then
        hmiDefaultCap[pMod].IsReady.params.available = true
      end
    end
  end
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

local function removedRaduantParameters()
  hmiCapabilities.UI.displayCapabilities.imageCapabilities = nil  -- no Mobile_API.xml
  hmiCapabilities.UI.displayCapabilities.menuLayoutsAvailable = nil --since 6.0
  return hmiCapabilities.UI.displayCapabilities
end

local function expCapRaiResponse( pMod, pReq)
  local capRaiResponse = {
    UI = {
      GetCapabilities = {
        audioPassThruCapabilities = changeBitsPSEnumAudioCap(hmiCapabilities.UI.audioPassThruCapabilities),
        pcmStreamCapabilities = changeBitsPSEnumPcmCap(hmiCapabilities.UI.pcmStreamCapabilities),
        hmiZoneCapabilitie = hmiCapabilities.UI.hmiZoneCapabilitie,
        softButtonCapabilities = hmiCapabilities.UI.softButtonCapabilities,
        displayCapabilities = removedRaduantParameters(),
      },
      GetLanguage = {
        hmiDisplayLanguage =  hmiCapabilities.UI.language }},
    VR = {
      GetCapabilities = {
        vrCapabilities = hmiCapabilities.VR.capabilities },
      GetLanguage = {
        language = hmiCapabilities.VR.language,}},
    TTS = {
      GetCapabilities = {
        speechCapabilities = hmiCapabilities.TTS.capabilities },
      GetLanguage = {
        language = hmiCapabilities.TTS.language}},
    Buttons = {
      GetCapabilities = {
        buttonCapabilities = hmiCapabilities.Buttons.capabilities }},
    VehicleInfo = {
      GetVehicleType  = {
        vehicleType = hmiCapabilities.VehicleInfo.vehicleType }}
    }
  return capRaiResponse[pMod][pReq]
end

--[[ Scenario ]]
for mod, req  in pairs(requests) do
  for _, pReq  in ipairs(req) do
    common.Title("Preconditions")
    common.Title("TC processing " .. tostring(mod) .." " .. tostring(pReq).."]")
    common.Step("Clean environment", common.preconditions)

    common.Title("Test")
    common.Step("Updated HMI Capabilities", updateHMICaps, { mod, pReq })
    common.Step("Ignition on, Start SDL, HMI", common.start, { hmiDefaultCap })
    common.Step("App registration", common.registerApp, { appSessionId, expCapRaiResponse(mod, pReq) })

    common.Title("Postconditions")
    common.Step("Stop SDL", common.postconditions)
  end
end
