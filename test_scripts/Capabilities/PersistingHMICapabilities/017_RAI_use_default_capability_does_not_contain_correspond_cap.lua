---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0249-Persisting-HMI-Capabilities-specific-to-headunit.md
--
-- Description: Check that the SDL use default capabilities from hmi_capabilities.json in case
-- HMI does not send one of GetCapabilities/GetLanguage/GetVehicleType response due to timeout

-- Preconditions:
-- 1  Value of HMICapabilitiesCacheFile parameter is defined (hmi_capabilities_cache.json) in smartDeviceLink.ini file
-- 2. HMI capability cache file (hmi_capabilities_cache.json) doesn't exist on file system
-- 3. SDL and HMI are started
-- 4. HMI does not provide one of HMI capabilities (VR/TTS/RC/UI etc)
-- 5. App is registered
-- Sequence:
-- 1. Mobile sends RegisterAppInterface request to SDL
--  a. SDL sends RegisterAppInterface response with correspond capabilities (stored in hmi_capabilities.json) to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local appSessionId = 1
local hmiDefaultCap = common.getDefaultHMITable()
local hmiCapabilities = common.updatedHMICapabilitiesTable()

local requests = {
  UI = { "GetCapabilities" },
  VR = { "GetCapabilities" },
  TTS = { "GetCapabilities" },
  Buttons = { "GetCapabilities" },
  VehicleInfo = { "GetVehicleType" }
}

--[[ Local Functions ]]
local function updateHMICaps(pMod, pRequest)
  for key, _ in pairs (hmiDefaultCap) do
    if key == pMod then
      hmiDefaultCap[pMod][pRequest] = nil
      if not pMod == "Buttons" then
        hmiDefaultCap[pMod].IsReady.params.available = true
      end
    end
  end
end

local function changeInternalNameRate(pCapabilities)
  local capTable = common.cloneTable(pCapabilities)
    capTable.bitsPerSample = string.gsub(capTable.bitsPerSample, "RATE_", "")
    capTable.samplingRate = string.gsub(capTable.samplingRate, "RATE_", "")
  return capTable
end

local function changeInternalNameRateArray(pCapabilities)
  local capTableArray = common.cloneTable(pCapabilities)
  for key, value in ipairs(capTableArray) do
    capTableArray[key] = changeInternalNameRate(value)
  end
  return capTableArray
end

local function removedRaduantParameters()
  hmiCapabilities.UI.displayCapabilities.imageCapabilities = nil  -- no Mobile_API.xml
  hmiCapabilities.UI.displayCapabilities.menuLayoutsAvailable = nil --since 6.0
  return hmiCapabilities.UI.displayCapabilities
end

local function expCapRaiResponse(pMod, pReq)
  local capRaiResponse = {
    UI = {
      GetCapabilities = {
        audioPassThruCapabilities = changeInternalNameRateArray(hmiCapabilities.UI.audioPassThruCapabilities),
        pcmStreamCapabilities = changeInternalNameRate(hmiCapabilities.UI.pcmStreamCapabilities),
        hmiZoneCapabilities = hmiCapabilities.UI.hmiZoneCapabilities,
        softButtonCapabilities = hmiCapabilities.UI.softButtonCapabilities,
        displayCapabilities = removedRaduantParameters(),
      },
      GetLanguage = {
        hmiDisplayLanguage =  hmiCapabilities.UI.language }},
    VR = {
      GetCapabilities = {
        vrCapabilities = hmiCapabilities.VR.vrCapabilities },
      GetLanguage = {
        language = hmiCapabilities.VR.language }},
    TTS = {
      GetCapabilities = {
        speechCapabilities = hmiCapabilities.TTS.speechCapabilities,
        prerecordedSpeech = hmiCapabilities.TTS.prerecordedSpeechCapabilities },
      GetLanguage = {
        language = hmiCapabilities.TTS.language }},
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
for mod, request  in pairs(requests) do
  for _, req  in ipairs(request) do
    common.Title("Preconditions")
    common.Title("TC processing " .. tostring(mod) .. " " .. tostring(req) .. "]")
    common.Step("Clean environment", common.preconditions)
    common.Step("Update HMI capabilities", common.updatedHMICapabilitiesFile)
    common.Step("HMI does not response on " .. mod .. "." .. req, updateHMICaps, { mod, req })

    common.Title("Test")
    common.Step("Ignition on, Start SDL, HMI", common.start, { hmiDefaultCap })
    common.Step("App registration", common.registerApp, { appSessionId, expCapRaiResponse(mod, req) })

    common.Title("Postconditions")
    common.Step("Stop SDL", common.postconditions)
  end
end
