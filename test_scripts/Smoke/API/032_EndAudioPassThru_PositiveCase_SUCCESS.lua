---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: EndAudioPassThru
-- Item: Happy path
--
-- Requirement summary:
-- [EndAudioPassThru] SUCCESS: getting SUCCESS:UI.EndAudioPassThru()
--
-- Description:
-- Mobile application sends valid EndAudioPassThru request and gets UI.EndAudioPassThru "SUCCESS"
-- response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests EndAudioPassThru with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if EndAudioPassThru is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
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

local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams,
}

--[[ Local Functions ]]
local function sendOnSystemContext(pCtx, pAppID)
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { appID = pAppID, systemContext = pCtx })
end

local function endAudioPassThru(pParams)
  local uiPerformID
  local cid = common.getMobileSession():SendRPC("PerformAudioPassThru", pParams.requestParams)
  pParams.requestUiParams.appID = common.getHMIAppId()
  common.getHMIConnection():ExpectRequest("UI.PerformAudioPassThru", pParams.requestUiParams)
  :Do(function(_, data)
      sendOnSystemContext("HMI_OBSCURED", pParams.requestUiParams.appID)
      uiPerformID = data.id
    end)
  common.getHMIConnection():ExpectNotification("UI.OnRecordStart", { appID = pParams.requestUiParams.appID })
  common.getMobileSession():ExpectNotification("OnAudioPassThru")
  :Do(function()
      local cidEndAudioPassThru = common.getMobileSession():SendRPC("EndAudioPassThru", { })
      common.getHMIConnection():ExpectRequest("UI.EndAudioPassThru")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
          common.getHMIConnection():SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", { })
          sendOnSystemContext("MAIN", pParams.requestUiParams.appID)
        end)
      common.getMobileSession():ExpectResponse(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS" })
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(2)
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
runner.Step("EndAudioPassThru Positive Case", endAudioPassThru, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
