---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1384
-- Description: SDL doesn't check result codes of HMI IsReady response
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) SDL receives TTS.IsReady (error_result_code, available=true) from the HMI
-- 3) App is registered and activated
-- In case:
-- 1) App requests SetGlobalProperties with the both vrCommands and menuParams
-- Expected result:
-- 1) SDL transfers only UI.SetGlobalProperties request to the HMI and
--    respond with 'UNSUPPORTED_RESOURCE, success:true,' + 'info: TTS is not supported by system'
-- Actual result:
-- SDL responds with GENERIC_ERROR, success=false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.TTS = nil
  return params
end

local requestParams = {
  helpPrompt = {
    { text = "Help prompt", type = "TEXT" }
  },
  timeoutPrompt = {
    { text = "Timeout prompt", type = "TEXT" }
  },
  vrHelpTitle = "VR help title",
  vrHelp = {
    {
      position = 1,
      text = "VR help item"
    }
  },
  menuTitle = "Menu Title",
  keyboardProperties = {
    keyboardLayout = "QWERTY",
    keypressMode = "SINGLE_KEYPRESS",
    limitedCharacterList = {"a"},
    language = "EN-US",
    autoCompleteList = { "Daemon" , "Freedom" }
  }
}

local responseUiParams = {
  vrHelpTitle = requestParams.vrHelpTitle,
  vrHelp = requestParams.vrHelp,
  menuTitle = requestParams.menuTitle,
  keyboardProperties = requestParams.keyboardProperties
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams
}
--[[ Local Functions ]]
local function start (pHMIvalues)
  common.start(pHMIvalues)
  common.getHMIConnection():ExpectRequest("TTS.IsReady")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "REJECTED", { available = true })
  end)
end

local function sendSetGlobalProperties(params)
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", params.requestParams)
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", params.responseUiParams)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getMobileSession():ExpectResponse(cid,
  { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "TTS is not supported by system" })
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start, { getHMIValues() })
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Sends SetGlobalProperties", sendSetGlobalProperties, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
