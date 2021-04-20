---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: SetGlobalProperties
-- Item: Happy path
--
-- Requirement summary:
-- [SetGlobalProperties] SUCCESS on TTS.SetGlobalProperties and UI.SetGlobalProperties
--
-- Description:
-- In case mobile application sends valid SetGlobalproperties_request with "timeoutPrompt"
-- and/or "helpPrompt" and at least one other valid parameter, SDL must transfer from mobile
-- app to HMI the both UI.SetGlobalProperties and TTS.SetGlobalProperties. On getting "SUCCESS"
-- result code from the both HMI-portions, SDL must transfer "resutCode:SUCCESS", success:"true"
-- to mobile application.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests SetGlobalproperties with timeoutPrompt, helpPrompt and other valid parameters

-- Expected:

-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if TTS interface is available on HMI
-- SDL checks if SetGlobalproperties is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL transfers the TTS part of request with allowed parameters to HMI
-- SDL receives UI and TTS part of response from HMI with "SUCCESS" result code
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local putFileParams = {
  requestParams = {
    syncFileName = 'icon.png',
    fileType = "GRAPHIC_PNG",
    persistentFile = false,
    systemFile = false
  },
  filePath = "files/icon.png"
}

local requestParams = {
	helpPrompt = {
		{
			text = "Help prompt",
			type = "TEXT"
		}
	},
	timeoutPrompt =	{
		{
			text = "Timeout prompt",
			type = "TEXT"
		}
	},
	vrHelpTitle = "VR help title",
	vrHelp = {
		{
			position = 1,
			image = {
				value = "icon.png",
				imageType = "DYNAMIC"
			},
			text = "VR help item"
		}
	},
	menuTitle = "Menu Title",
	menuIcon = {
		value = "icon.png",
		imageType = "DYNAMIC"
	},
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
  menuIcon = requestParams.menuIcon,
  keyboardProperties = requestParams.keyboardProperties
}

local responseTtsParams = {
  timeoutPrompt = requestParams.timeoutPrompt,
  helpPrompt = requestParams.helpPrompt
}

local allParams = {
  requestParams = requestParams,
  responseUiParams = responseUiParams,
  responseTtsParams = responseTtsParams
}

--[[ Local Functions ]]
local function setGlobalProperties(pParams)
  local cid = common.getMobileSession():SendRPC("SetGlobalProperties", pParams.requestParams)

  pParams.responseUiParams.appID = common.getHMIAppId()
  pParams.responseUiParams.vrHelp[1].image.value = common.getPathToFileInAppStorage("icon.png")
  pParams.responseUiParams.menuIcon.value = common.getPathToFileInAppStorage("icon.png")
  common.getHMIConnection():ExpectRequest("UI.SetGlobalProperties", pParams.responseUiParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

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
runner.Step("Upload icon file", common.putFile, { putFileParams })

runner.Title("Test")
runner.Step("SetGlobalProperties Positive Case", setGlobalProperties, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
