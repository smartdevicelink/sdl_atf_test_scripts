---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: PerformAudioPassThru
-- Item: Happy path
--
-- Requirement summary:
-- [PerformAudioPassThru] SUCCESS: getting SUCCESS:UI.PerformAudioPassThru()
--
-- Description:
-- Mobile application sends valid PerformAudioPassThru request and gets UI.PerformAudioPassThru "SUCCESS"
-- response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests PerformAudioPassThru with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if TTS interface is available on HMI
-- SDL checks if PerformAudioPassThru is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL transfers the TTS part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL receives TTS part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Variables ]]
local requestParams = {
  initialPrompt = {
    {
      text = "Makeyourchoice",
      type = "TEXT",
    },
  },
  audioPassThruDisplayText1 = "DisplayText1",
  audioPassThruDisplayText2 = "DisplayText2",
  samplingRate = "8KHZ",
  maxDuration = 2000,
  bitsPerSample = "8_BIT",
  audioType = "PCM",
  muteAudio = true
}

local requestUiParams = {
  audioPassThruDisplayTexts = { },
  maxDuration = requestParams.maxDuration,
  muteAudio = requestParams.muteAudio
}

requestUiParams.audioPassThruDisplayTexts[1] = {
  fieldName = "audioPassThruDisplayText1",
  fieldText = requestParams.audioPassThruDisplayText1
}

requestUiParams.audioPassThruDisplayTexts[2] = {
  fieldName = "audioPassThruDisplayText2",
  fieldText = requestParams.audioPassThruDisplayText2
}

local requestTtsParams = {}
requestTtsParams.ttsChunks = common.cloneTable(requestParams.initialPrompt)
requestTtsParams.speakType = "AUDIO_PASS_THRU"

local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams,
  requestTtsParams = requestTtsParams
}

--[[ Local Functions ]]
local function sendOnSystemContext(pCtx, pAppID)
  common.getHMIConnection():SendNotification("UI.OnSystemContext", { appID = pAppID, systemContext = pCtx })
end

local function performAudioPassThru(pParams)
  local cid = common.getMobileSession():SendRPC("PerformAudioPassThru", pParams.requestParams)
  pParams.requestUiParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("TTS.Speak", pParams.requestTtsParams)
  :Do(function(_, data)
      common.getHMIConnection():SendNotification("TTS.Started")
      local function ttsSpeakResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      common.runAfter(ttsSpeakResponse, 50)
    end)
  common.getHMIConnection():ExpectRequest("UI.PerformAudioPassThru", pParams.requestUiParams)
  :Do(function(_, data)
      sendOnSystemContext("HMI_OBSCURED", pParams.requestUiParams.appID)
      local function uiResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
        sendOnSystemContext("MAIN", pParams.requestUiParams.appID)
      end
      common.runAfter(uiResponse, 1500)
    end)
  EXPECT_HMINOTIFICATION("UI.OnRecordStart", { appID = pParams.requestUiParams.appID })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED" },
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  :Times(2)
  common.getMobileSession():ExpectNotification("OnAudioPassThru")
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf(function()
      if common.isFileExistInAppStorage("audio.wav") ~= true then
      return false, "Can not found file: audio.wav"
    end
    return true
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("PerformAudioPassThru Positive Case", performAudioPassThru, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
