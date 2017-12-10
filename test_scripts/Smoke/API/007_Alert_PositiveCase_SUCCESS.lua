---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: Alert
-- Item: Happy path
--
-- Requirement summary:
-- [Alert] SUCCESS: request with UI portion and TTSChunks
--
-- Description:
-- Mobile application sends valid Alert request with UI-related-params & with TTSChunks
-- and gets SUCCESS resultCode to both UI.Alert and TTS.Speak from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests Alert with UI-related-params & with TTSChunks

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if TTS interface is available on HMI
-- SDL checks if Alert is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI.Alert part of request with allowed parameters to HMI
-- SDL transfers the TTS.Speak part of request with allowed parameters to HMI
-- SDL receives UI.Alert part of response from HMI with "SUCCESS" result code
-- SDL receives TTS.Speak part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
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

local step1SpecificParams = {
	softButtons = {
		{
			type = "BOTH",
			text = "Close",
		 	image = {
				value = "icon.png",
				imageType = "DYNAMIC",
			},
			isHighlighted = true,
			softButtonID = 3,
			systemAction = "DEFAULT_ACTION",
		},
		{
			type = "TEXT",
			text = "Keep",
			isHighlighted = true,
			softButtonID = 4,
			systemAction = "KEEP_CONTEXT",
		},
		{
			type = "IMAGE",
		 	image = {
				value = "icon.png",
				imageType = "DYNAMIC",
			},
			softButtonID = 5,
			systemAction = "STEAL_FOCUS",
		}
	}
}

local step2SpecificParams = {
	duration = 5000
}

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
	progressIndicator = true
}

local responseUiParams = {
	alertStrings = {
		{
			fieldName = requestParams.alertText1,
			fieldText = requestParams.alertText1
		},
		{
			fieldName = requestParams.alertText2,
			fieldText = requestParams.alertText2
		},
		{
			fieldName = requestParams.alertText3,
			fieldText = requestParams.alertText3
		}
	},
	alertType = "BOTH",
	progressIndicator = requestParams.progressIndicator,
}

local ttsSpeakRequestParams = {
	ttsChunks = requestParams.ttsChunks,
	speakType = "ALERT",
	playTone = requestParams.playTone
}

local allParams = {
	requestParams = requestParams,
	responseUiParams = responseUiParams,
	ttsSpeakRequestParams = ttsSpeakRequestParams
}

--[[ Local Functions ]]
local function sendOnSystemContext(self, ctx)
  	self.hmiConnection:SendNotification("UI.OnSystemContext",
  		{
  			appID = commonSmoke.getHMIAppId(),
  			systemContext = ctx
  		})
end

local function prepareAlertParams(params, additionalParams)
	params.responseUiParams.appID = commonSmoke.getHMIAppId()

	if additionalParams.softButtons ~= nil then
		params.requestParams.duration = nil
		params.requestParams.softButtons = additionalParams.softButtons
		params.responseUiParams.duration = nil;
		params.responseUiParams.softButtons = additionalParams.softButtons
		params.responseUiParams.softButtons[1].image.value =
			commonSmoke.getPathToFileInStorage(putFileParams.requestParams.syncFileName)
		params.responseUiParams.softButtons[3].image.value =
			commonSmoke.getPathToFileInStorage(putFileParams.requestParams.syncFileName)
	elseif additionalParams.duration ~= nil then
		params.requestParams.softButtons = nil
		params.requestParams.duration = additionalParams.duration
		params.responseUiParams.softButtons = nil
		params.responseUiParams.duration = additionalParams.duration
	end
end

local function alert(params, additionalParams, self)
	prepareAlertParams(params, additionalParams)

	local responseDelay = 3000
	local cid = self.mobileSession1:SendRPC("Alert", params.requestParams)

	EXPECT_HMICALL("UI.Alert", params.responseUiParams)
	:Do(function(_,data)
		sendOnSystemContext(self, "ALERT")

		local alertId = data.id
		local function alertResponse()
			self.hmiConnection:SendResponse(alertId, "UI.Alert", "SUCCESS", { })
			sendOnSystemContext(self, "MAIN")
		end

		RUN_AFTER(alertResponse, responseDelay)
	end)

	params.ttsSpeakRequestParams.appID = commonSmoke.getHMIAppId()
	EXPECT_HMICALL("TTS.Speak", params.ttsSpeakRequestParams)
	:Do(function(_,data)
		self.hmiConnection:SendNotification("TTS.Started")

		local speakId = data.id
		local function speakResponse()
			self.hmiConnection:SendResponse(speakId, "TTS.Speak", "SUCCESS", { })
			self.hmiConnection:SendNotification("TTS.Stopped")
		end

		RUN_AFTER(speakResponse, responseDelay - 1000)
	end)
	:ValidIf(function(_,data)
		if #data.params.ttsChunks == 1 then
			return true
		else
			return false, "ttsChunks array in TTS.Speak request has wrong element number." ..
			" Expected 1, actual " .. tostring(#data.params.ttsChunks)
		end
	end)

	commonSmoke.expectOnHMIStatusWithAudioStateChanged(self)

	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)
runner.Step("Upload icon file", commonSmoke.putFile, {putFileParams})

runner.Title("Test")
runner.Step("Alert with soft buttons Positive Case", alert, {allParams, step1SpecificParams})
runner.Step("Alert with duration Positive Case", alert, {allParams, step2SpecificParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
