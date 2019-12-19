---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1006
-- Description: PoliciesManager must allow all requested params in case "parameters" field is omitted
-- Precondition:
-- 1) SDL and HMI are started.
-- In case:
-- 1) Send any single UI-related RPC , UI interface is not supported by the system
-- 2) SDL receives UI.IsReady (available=false) from HMI
-- Expected result:
-- 1) SDL must respond "UNSUPPORTED_RESOURCE, success=false, info: UI is not supported by system" to mobile app
-- Actual result:
-- SDL responds with GENERIC_ERROR, success=false (logs are in attachment)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local buttonName = {
  "OK",
  "PLAY_PAUSE",
  "SEEKLEFT",
  "SEEKRIGHT",
  "TUNEUP",
  "TUNEDOWN",
  "PRESET_0",
  "PRESET_1",
  "PRESET_2",
  "PRESET_3",
  "PRESET_4",
  "PRESET_5",
  "PRESET_6",
  "PRESET_7",
  "PRESET_8"
}

--[[ Local Functions ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.UI.IsReady.params.available = false
  params.UI.GetCapabilities = nil
  params.UI.GetLanguage = nil
  params.UI.GetSupportedLanguages = nil
  return params
end

local function sendSubscribeButton(pButName)
  local cid = common.getMobileSession():SendRPC("SubscribeButton", { buttonName = pButName })
  common.getMobileSession():ExpectResponse(cid, {success = false, resultCode = "UNSUPPORTED_RESOURCE"})
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {getHMIValues()})
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, v in pairs(buttonName) do
  runner.Step("Sends SubscribeButton " .. v .. " UNSUPPORTED_RESOURCE", sendSubscribeButton, {v})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
