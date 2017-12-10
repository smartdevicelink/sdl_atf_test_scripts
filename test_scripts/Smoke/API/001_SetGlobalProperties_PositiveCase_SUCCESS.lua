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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

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
		autoCompleteText = "Daemon, Freedom"
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
local function setGlobalProperties(params, self)
	local cid = self.mobileSession1:SendRPC("SetGlobalProperties", params.requestParams)

	params.responseUiParams.appID = commonSmoke.getHMIAppId()
	params.responseUiParams.vrHelp[1].image.value = commonSmoke.getPathToFileInStorage("icon.png")
	params.responseUiParams.menuIcon.value = commonSmoke.getPathToFileInStorage("icon.png")
	EXPECT_HMICALL("UI.SetGlobalProperties", params.responseUiParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	params.responseTtsParams.appID = commonSmoke.getHMIAppId()
	EXPECT_HMICALL("TTS.SetGlobalProperties", params.responseTtsParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	self.mobileSession1:ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, {putFileParams})

runner.Title("Test")
runner.Step("SetGlobalProperties Positive Case", setGlobalProperties, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
