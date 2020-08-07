---------------------------------------------------------------------------------------------------
-- User story: SubtleAlert cases
-- Use case: SubtleAlert
-- Item: Happy path (STEAL_FOCUS softbutton pressed)
--
-- Requirement summary:
-- [SubtleAlert] SUCCESS: request with UI portion including STEAL_FOCUS softbutton and TTSChunks
-- in background
--
-- Description:
-- Mobile application sends valid SubtleAlert request in background with UI-related-params & with 
-- TTSChunks and gets SUCCESS resultCode to both UI.SubtleAlert and TTS.Speak from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID1 is registered on SDL
-- c. appID1 is currently in Background HMI level
-- d. appID1 has policy permissions to send SubtleAlert in background
-- e. appID1 has policy priority greater than NONE
-- f. appID2 is registered and activated on SDL

-- Steps:
-- appID1 requests SubtleAlert with UI-related-params & with TTSChunks
-- User selects STEAL_FOCUS button in SubtleAlert prompt

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if TTS interface is available on HMI
-- SDL checks if SubtleAlert is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI.SubtleAlert part of request with allowed parameters to HMI
-- SDL transfers the TTS.Speak part of request with allowed parameters to HMI
-- SDL receives TTS.Speak part of response from HMI with "SUCCESS" result code
-- SDL receives Buttons.OnButtonEvent/OnButtonPress notification for STEAL_FOCUS softbutton
-- SDL receives SDL.ActivateApp request for appID1 and responds with success,
-- appID1 is brought to the foreground while appID2 is put in background
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

local function subtleAlertTwoApps(pParams)
  local params = prepareParams(pParams)

  local cid = common.getMobileSession():SendRPC("SubtleAlert", params.requestParams)

  common.getHMIConnection():ExpectRequest("UI.SubtleAlert", params.uiRequestParams)
  :Do(function(_, data)
      common.sendOnSystemContext("ALERT")
      common.sendOnSystemContext("HMI_OBSCURED", 2)
      local function alertResponseStealFocus()
        local buttonID = requestParams.softButtons[2].softButtonID
        common.getHMIConnection():SendNotification("Buttons.OnButtonEvent", { 
          name = "CUSTOM_BUTTON", customButtonID = buttonID, 
          mode = "BUTTONDOWN", appID = common.getHMIAppId() 
        })
        common.getHMIConnection():SendNotification("Buttons.OnButtonEvent", { 
          name = "CUSTOM_BUTTON", customButtonID = buttonID, 
          mode = "BUTTONUP", appID = common.getHMIAppId() 
        })
        common.getHMIConnection():SendNotification("Buttons.OnButtonPress", { 
          name = "CUSTOM_BUTTON", customButtonID = buttonID, 
          mode = "SHORT", appID = common.getHMIAppId() 
        })
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })

        local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
        common.getHMIConnection():ExpectResponse(requestId)

        common.sendOnSystemContext("MAIN")
        common.sendOnSystemContext("MAIN", 2)
      end
      common.runAfter(alertResponseStealFocus, 3000)
    end)

  params.ttsSpeakRequestParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("TTS.Speak", params.ttsSpeakRequestParams)
  :Do(function(_, data)
      common.getHMIConnection():SendNotification("TTS.Started")
      local function speakResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      common.runAfter(speakResponse, 2000)
    end)
  :ValidIf(function(_, data)
      if #data.params.ttsChunks == 1 then
        return true
      else
        return false, "ttsChunks array in TTS.Speak request has wrong element number."
          .. " Expected 1, actual " .. tostring(#data.params.ttsChunks)
      end
    end)

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "ALERT", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" },
    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(3)

  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "HMI_OBSCURED", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" },
    { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" })
  :Times(5)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Register App 2", common.registerApp, { 2 })
runner.Step("Activate App 2", common.activateApp, { 2 })
runner.Step("Upload icon file", common.putFile, { { requestParams = putFileParams, filePath = iconFilePath } })

runner.Title("Test")
runner.Step("SubtleAlert with two apps STEAL_FOCUS Positive Case", subtleAlertTwoApps, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
