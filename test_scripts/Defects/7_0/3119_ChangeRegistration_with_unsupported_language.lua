---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3119
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local language = "DE-DE"

--[[ Local Functions ]]
local function changeRegistration()
  local params = {
    language = language,
    hmiDisplayLanguage = language,
  }
  local cid = common.getMobileSession():SendRPC("ChangeRegistration", params)
  for _, iface in pairs({ "UI", "VR", "TTS" }) do
    common.getHMIConnection():ExpectRequest(iface .. ".ChangeRegistration"):Times(0)
  end
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
end


local function getHMIParams()
  local params = hmi_values.getDefaultHMITable()
  for _, iface in pairs({ "UI", "VR", "TTS" }) do
    local languages = params[iface].GetSupportedLanguages.params.languages
    for k, v in pairs(languages) do
      if v == language then
        table.remove(languages, k)
        break
      end
    end
  end
  return params
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getHMIParams() })
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("Change language for App", changeRegistration)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)