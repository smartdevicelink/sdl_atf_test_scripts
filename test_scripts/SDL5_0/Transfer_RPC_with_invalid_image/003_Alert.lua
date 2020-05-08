---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests Alert with image that is absent on file system
-- SDL must:
-- 1. transfer this RPC to HMI for processing
-- 2. transfer the received from HMI response (WARNINGS, message: “Requested image(s) not found”) to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variable s ]]
local softButtons  = {
  softButtons = {
    {
      type = "BOTH",
      text = "Close",
      image = {
        value = "missed_icon.png",
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
        value = "missed_icon.png",
        imageType = "DYNAMIC",
      },
      softButtonID = 5,
      systemAction = "STEAL_FOCUS",
    }
  }
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
  progressIndicator = true,
  alertIcon = {
    value = "icon.png",
    imageType = "DYNAMIC"
  }
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
local function sendOnSystemContext(pCtx)
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
  {
    appID = common.getHMIAppId(),
    systemContext = pCtx
  })
end

local function prepareAlertParams(pParams, pAdditionalParams)
  pParams.responseUiParams.appID = common.getHMIAppId()
  pParams.requestParams.duration = nil
  pParams.requestParams.softButtons = pAdditionalParams.softButtons
  pParams.responseUiParams.duration = nil;
  pParams.responseUiParams.softButtons = pAdditionalParams.softButtons
  pParams.responseUiParams.softButtons[1].image.value =
    common.getPathToFileInStorage(pAdditionalParams.softButtons[1].image.value)
  pParams.responseUiParams.softButtons[3].image.value =
    common.getPathToFileInStorage(pAdditionalParams.softButtons[3].image.value)
end

local function alert(pParams, pAdditionalParams)
  prepareAlertParams(pParams, pAdditionalParams)

  local responseDelay = 3000
  local cid = common.getMobileSession():SendRPC("Alert", pParams.requestParams)

  EXPECT_HMICALL("UI.Alert", pParams.responseUiParams)
  :Do(function(_,data)
      sendOnSystemContext("ALERT")

      local alertId = data.id
      local function alertResponse()
        common.getHMIConnection():SendError(alertId, "UI.Alert", "WARNINGS", "Requested image(s) not found")
        sendOnSystemContext("MAIN")
      end

      RUN_AFTER(alertResponse, responseDelay)
    end)

  pParams.ttsSpeakRequestParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("TTS.Speak", pParams.ttsSpeakRequestParams)
  :Do(function(_,data)
      common.getHMIConnection():SendNotification("TTS.Started")

      local speakId = data.id
      local function speakResponse()
        common.getHMIConnection():SendResponse(speakId, "TTS.Speak", "SUCCESS", { })
        common.getHMIConnection():SendNotification("TTS.Stopped")
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

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(4)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS",
    info = "Requested image(s) not found" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Alert with soft buttons with invalid image", alert, { allParams, softButtons })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
