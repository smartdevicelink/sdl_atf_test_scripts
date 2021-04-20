---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: ResetGlobalProperties
-- Item: Happy path
--
-- Requirement summary:
-- [ResetGlobalProperties] SUCCESS on UI.SetGlobalProperties and TTS.SetGlobalPrtoperties
--
-- Description:
-- Mobile app sends valid ResetGlobalProperties with "HELPPROMPT" and "TIMEOUTPROMPT"
-- and at least one other valid parameter in "properties" array

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests ResetGlobalProperties with timeoutPrompt, helpPrompt and other valid parameters

-- Expected:

-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if TTS interface is available on HMI
-- SDL checks if ResetGlobalProperties is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL setup the value of helpPrompt to an empty array and retrieve the value of timeoutPrompt
-- parameter from .ini file correspondingly
-- SDL transfer the items requested ("HELPPROMPT" and "TIMEOUTPROMPT"):
-- TTS.SetGlobalProperties(helpPrompt:"<empty array>", and timeoutPrompt:<'TimeOutPrompt' from ini.file>) to HMI
-- SDL responds (resultCode:SUCCESS, success:true) to mobile application on getting the both
-- SUCCESS:UI.SetGlobalProperties and SUCCESS:TTS.SetGlobalProperties from HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  properties = {
    "VRHELPTITLE",
    "MENUNAME",
    "MENUICON",
    "KEYBOARDPROPERTIES",
    "VRHELPITEMS",
    "HELPPROMPT",
    "TIMEOUTPROMPT"
  }
}

local responseUiParams = {
	menuTitle = "",
	vrHelpTitle = "Available Vr Commands List",
	keyboardProperties = {
		keyboardLayout = "QWERTY",
		autoCompleteList = {},
		language = "EN-US"
  },
  vrHelp = {
    {
      position = 1,
      text = "Test Application"
    }
  }
}

local responseTtsParams = {
  helpPrompt = {
    {
      text = "Please speak one of the following commands,",
      type = "TEXT"
    },
    {
      text = "Please say a command,",
      type = "TEXT"
    }
  },
  timeoutPrompt = {}
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
  responseTtsParams = responseTtsParams
}

--[[ Local Functions ]]
local function splitString(pInputStr, pSep)
  if pSep == nil then
    pSep = "%s"
  end
  local out, i = {}, 1
  for str in string.gmatch(pInputStr, "([^" .. pSep .. "]+)") do
    out[i] = str
    i = i + 1
  end
  return out
end

local function resetGlobalProperties(pParams)
  local cid = common.getMobileSession():SendRPC("ResetGlobalProperties", pParams.requestParams)

  pParams.responseUiParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", pParams.responseUiParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  local ttsDelimiter = common.readParameterFromSDLINI("TTSDelimiter")
  local helpPromptString = common.readParameterFromSDLINI("HelpPromt")
  local helpPromptList = splitString(helpPromptString, ttsDelimiter)

  for key, value in pairs(helpPromptList) do
    pParams.responseTtsParams.timeoutPrompt[key] = {
      type = "TEXT",
      text = value .. ttsDelimiter
    }
  end

  pParams.responseTtsParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("TTS.SetGlobalProperties", pParams.responseTtsParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("ResetGlobalProperties Positive Case", resetGlobalProperties, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
