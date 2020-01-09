---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1006
-- Description: SDL responses with GENERIC_ERROR instead of UNSUPPORTED_RESOURCE
-- Precondition:
-- 1) SDL and HMI are started.
-- In case:
-- 1) Any single UI-related RPC is requested , UI interface is not supported by the system
-- 2) SDL receives UI.IsReady (available=false) from HMI
-- Expected result:
-- 1) SDL must respond "UNSUPPORTED_RESOURCE, success=false, info: UI is not supported by system" to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  alertText1 = "alertText1",
  alertText2 = "alertText2",
  alertText3 = "alertText3",
  ttsChunks = {
    {
      text = "TTSChunk",
      type = "TEXT",
    }
  },
  playTone = true,
  progressIndicator = true,
  alertIcon = {
    value = "icon.png",
    imageType = "DYNAMIC"
  }
}
local ttsSpeakRequestParams = {
  ttsChunks = requestParams.ttsChunks,
  speakType = "ALERT",
  playTone = requestParams.playTone
}

local allParams = {
  requestParams = requestParams,
  ttsSpeakRequestParams = ttsSpeakRequestParams
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

local function sendAlert(params)
  local cid = common.getMobileSession():SendRPC("Alert", params.requestParams)
  common.getHMIConnection():ExpectRequest("UI.Alert")
  :Times(0)
  common.getHMIConnection():ExpectRequest("TTS.Speak", params.ttsSpeakRequestParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, "TTS.Speak", "SUCCESS", {})
    common.getHMIConnection():SendNotification("TTS.Stopped")
  end)
  common.getMobileSession():ExpectResponse(cid, {success = false, resultCode = "UNSUPPORTED_RESOURCE"})
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {getHMIValues()})
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Sends Alert", sendAlert, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
