---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0252-Aligning-HMI-and-MOBILE-API-for-pcmStreamCapabilities.md
--
-- Description: Applying the default pcmStreamCapabilities from hmi_capabilities.json
--   during the receiving of the invalid pcmStreamCapabilities from HMI
--
-- In case:
-- 1) HMI sends UI.GetCapabilities with invalid pcmStreamCapabilities value
-- SDL does:
--   a) apply the default capabilities from hmi_capabilities.json
-- 2) Mobile app is registered
-- SDL does:
--   a) send RAI response with default pcmStreamCapabilities value from hmi_capabilities.json
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Capabilities/pcmStreamCapabilities/commonPcmStreamCapabilities")

--[[ Local Variables ]]
local pcmStreamCapabilitiesValues = {
  missingSamplingRate = "samplingRate",
  missingBitsPerSample = "bitsPerSample",
  missingAudioType = "audioType",
  invalidTypeSamplingRate = {
    samplingRate = "DUMMY",
  },
  invalidTypeBitsPerSample = {
    bitsPerSample = "DUMMY",
  },
  invalidTypeAudioType = {
    audioType = "DUMMY"
  },
  emptyPcmStreamCapabilities = {}
}

--[[ Local Functions ]]
local function prepareTestData(pParams)
  local sendCapabilitiesData = common.cloneTable(common.hmiDefaultCapabilities)
  sendCapabilitiesData.UI.GetCapabilities.params.pcmStreamCapabilities = common.cloneTable(common.pcmStreamCapabilitiesValue)
  if type(pParams) == "table" then
    if next(pParams) then
      local key,value = next(pParams)
      sendCapabilitiesData.UI.GetCapabilities.params.pcmStreamCapabilities[key] = value
    else
      sendCapabilitiesData.UI.GetCapabilities.params.pcmStreamCapabilities = {}
    end
  elseif type(pParams) == "string" then
    sendCapabilitiesData.UI.GetCapabilities.params.pcmStreamCapabilities[pParams] = nil
  end
  return sendCapabilitiesData
end

--[[ Scenario ]]
for name, value in common.spairs(pcmStreamCapabilitiesValues) do
  common.Title(name .. "\n")
  common.Title("Preconditions")
  common.Step("Clean environment " .. name, common.preconditions)

  common.Title("Test")
  common.Step("Start SDL, HMI, connect Mobile, start Session " .. name, common.start, { prepareTestData(value) })
  common.Step("App registration " .. name, common.registerApp, { common.defaultPcmStreamCapabilities })

  common.Title("Postconditions")
  common.Step("Close mobile session " .. name, common.closeSession)
  common.Step("Stop SDL " .. name, common.postconditions)
end
