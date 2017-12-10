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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

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
	vrHelpTitle = "Test Application",
	keyboardProperties = {
		keyboardLayout = "QWERTY",
		autoCompleteText = "",
		language = "EN-US"
	}
}

local responseTtsParams = {
	helpPrompt = {},
	timeoutPrompt = {}
}

local allParams = {
	requestParams = requestParams,
	responseUiParams = responseUiParams,
	responseTtsParams = responseTtsParams
}

--[[ Local Functions ]]
local function resetGlobalProperties(params, self)
	local cid = self.mobileSession1:SendRPC("ResetGlobalProperties", params.requestParams)

	params.responseUiParams.appID = commonSmoke.getHMIAppId()
	EXPECT_HMICALL("UI.SetGlobalProperties", params.responseUiParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	:ValidIf(function(_,data)
		if data.params.vrHelp == nil then
			return true
		else
			return false, "vrHelp array in UI.SetGlobalProperties request is not empty." ..
			" Expected array size 0, actual " .. tostring(#data.params.vrHelp)
		end
	end)

	local ttsDelimiter = commonSmoke.readParameterFromSmartDeviceLinkIni("TTSDelimiter")
	local helpPromptString = commonSmoke.readParameterFromSmartDeviceLinkIni("HelpPromt")
	local helpPromptList = commonSmoke.splitString(helpPromptString, ttsDelimiter);

	for key,value in pairs(helpPromptList) do
		params.responseTtsParams.timeoutPrompt[key] = {
			type = "TEXT",
			text = value .. ttsDelimiter
		}
	end

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

runner.Title("Test")
runner.Step("ResetGlobalProperties Positive Case", resetGlobalProperties, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
