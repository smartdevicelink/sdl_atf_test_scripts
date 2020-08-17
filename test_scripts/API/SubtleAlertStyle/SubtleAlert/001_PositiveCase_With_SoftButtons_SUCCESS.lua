---------------------------------------------------------------------------------------------------
-- User story: SubtleAlert cases
-- Use case: SubtleAlert
-- Item: Happy path (with softbuttons)
--
-- Requirement summary:
-- [SubtleAlert] SUCCESS: request with UI portion including softbuttons and TTSChunks
--
-- Description:
-- Mobile application sends valid SubtleAlert request with UI-related-params & with TTSChunks
-- and gets SUCCESS resultCode to both UI.SubtleAlert and TTS.Speak from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Full or Limited HMI level

-- Steps:
-- appID requests SubtleAlert with UI-related-params & with TTSChunks

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if TTS interface is available on HMI
-- SDL checks if SubtleAlert is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI.SubtleAlert part of request with allowed parameters to HMI 
-- and without duration value
-- SDL transfers the TTS.Speak part of request with allowed parameters to HMI
-- SDL receives TTS.Speak part of response from HMI with "SUCCESS" result code
-- SDL receives UI.SubtleAlert part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SubtleAlertStyle/commonSubtleAlert')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local putFileParams = {
  syncFileName = "icon.png",
  fileType = "GRAPHIC_PNG",
  persistentFile = false,
  systemFile = false
}

local iconFilePath = "files/icon.png"

local requestParams = {
	alertText1 = "alertText1",
	alertText2 = "alertText2",
	ttsChunks = {
		{
			text = "TTSChunk",
			type = "TEXT",
		}
	},
	alertIcon = {
		value = "icon.png",
		imageType = "DYNAMIC"
	},
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

local uiRequestParams = {
  alertStrings = {
    {
      fieldName = "subtleAlertText1",
      fieldText = requestParams.alertText1
    },
    {
      fieldName = "subtleAlertText2",
      fieldText = requestParams.alertText2
    }
  },
  alertType = "BOTH",
  alertIcon = requestParams.alertIcon,
  softButtons = requestParams.softButtons
}

local ttsSpeakRequestParams = {
  ttsChunks = requestParams.ttsChunks,
  speakType = "SUBTLE_ALERT",
  playTone = requestParams.playTone
}

local allParams = {
  requestParams = requestParams,
  uiRequestParams = uiRequestParams,
  ttsSpeakRequestParams = ttsSpeakRequestParams
}

--[[ Local Functions ]]
local function prepareParams(pParams)
  local params = common.cloneTable(pParams)
  params.uiRequestParams.appID = common.getHMIAppId()
  params.uiRequestParams.alertIcon.value =
    common.getPathToFileInAppStorage(putFileParams.syncFileName)
  params.uiRequestParams.softButtons[1].image.value =
    common.getPathToFileInAppStorage(putFileParams.syncFileName)
  params.uiRequestParams.softButtons[2].image.value =
    common.getPathToFileInAppStorage(putFileParams.syncFileName)

  return params
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { { requestParams = putFileParams, filePath = iconFilePath } })

runner.Title("Test")
runner.Step("SubtleAlert with soft buttons Positive Case", common.subtleAlert, { allParams, prepareParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
