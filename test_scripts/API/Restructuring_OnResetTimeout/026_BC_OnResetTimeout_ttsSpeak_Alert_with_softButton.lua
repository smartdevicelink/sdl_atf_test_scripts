------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL does not reset timeout for Mobile app response for a specific RPC in case
-- - App sends request which is being split into 2 interfaces (UI.Alert, TTS.Speak)
-- - HMI sends 'OnResetTimeout(resetPeriod)' notification  for one request
-- Applicable RPCs: 'Alert' (with soft buttons), 'SubtleAlert' (with soft buttons)
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends RPC which is being split into 2 interfaces
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification for one interface to SDL right after receiving request with 'resetPeriod = 15s'
-- 4) HMI sends response after delay of 18s
-- SDL does:
--  - not apply default timeout
--  - not reset timeout once 'BC.OnResetTimeout' notification is received
--  - wait for the response from HMI
--  - once received it proceed with response successfully and transfer it to Mobile app
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Functions ]]
local function Alert(isSendingNotificationForUI, isSendingNotificationForTTS)
  local requestParams = {
    alertText1 = "alertText1",
    progressIndicator = true,
    duration = 3000,
    softButtons = {
      {
        softButtonID = 1,
        text = "Button",
        type = "TEXT",
        isHighlighted = false,
        systemAction = "DEFAULT_ACTION"
      }
    },
    ttsChunks = {
      { type = "TEXT",
        text = "pathToFile"
      }
    }
  }

  local cid = common.getMobileSession():SendRPC("Alert", requestParams)
  local requestTime = timestamp()

  common.getHMIConnection():ExpectRequest( "UI.Alert")
  :Do(function(_, data)
      if isSendingNotificationForUI == true then
        common.onResetTimeoutNotification(data.id, data.method, 15000)
      end
      local function sendresponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      RUN_AFTER(sendresponse, 18000)
    end)

  common.getHMIConnection():ExpectRequest("TTS.Speak", {
      ttsChunks = requestParams.ttsChunks,
      speakType = "ALERT",
      appID = common.getHMIAppId()
    })
  :Do(function(_, data)
      if isSendingNotificationForTTS == true then
        common.onResetTimeoutNotification(data.id, data.method, 15000)
      end
      local function SpeakResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      RUN_AFTER(SpeakResponse, 17000)
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(19000)
  :ValidIf(function()
      if isSendingNotificationForTTS == true or isSendingNotificationForUI == true then
        return common.responseTimeCalculationFromMobReq(18000, nil, requestTime)
      end
      return true
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Send Alert with ttsChunks and softButton", Alert)
common.Step("Send Alert with softButton, ttsChunks and onResetTimeout notification for UI.Alert",
  Alert, { true, false })
common.Step("Send Alert with softButton, ttsChunks and onResetTimeout notification for TTS.Speak",
  Alert, { false, true })
common.Step("Send Alert with softButton, ttsChunks and onResetTimeout notification for TTS.Speak and UI.Alert" ,
  Alert, { true, true })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
