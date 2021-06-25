------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check is able to reset timeout for Mobile app response for a specific RPC in case
-- - App sends request which is being split into 2 interfaces (Navigation.AlertManeuver, TTS.Speak)
-- - HMI sends 'OnResetTimeout(resetPeriod)' notification for one request
-- Applicable RPCs: 'AlertManeuver' (with soft buttons)
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends RPC which is being split into 2 interfaces
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification for one interface to SDL right after receiving request with 'resetPeriod = 15s'
-- 4) HMI sends response after delay of 12s
-- SDL does:
--  - wait for the response from HMI within reset period
--  - once received it proceed with response successfully and transfer it to Mobile app
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Functions ]]
local function AlertManeuver(pExpTimoutForMobResp, pExpTimeBetweenResp, isSendingNotificationForUI, isSendingNotificationForTTS)
  local requestParams = {
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
        text = "alertManeuver"
      }
    }
  }

  local cid = common.getMobileSession():SendRPC("AlertManeuver", requestParams)
  local requestTime = timestamp()

  common.getHMIConnection():ExpectRequest("Navigation.AlertManeuver")
  :Do(function(_, data)
      if isSendingNotificationForUI == true then
        common.onResetTimeoutNotification(data.id, data.method, 15000)
      end
      local function sendresponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      RUN_AFTER(sendresponse, pExpTimeBetweenResp)
    end)

  common.getHMIConnection():ExpectRequest("TTS.Speak", {
      ttsChunks = requestParams.ttsChunks,
      speakType = "ALERT_MANEUVER",
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
      RUN_AFTER(SpeakResponse, pExpTimeBetweenResp)
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(pExpTimoutForMobResp)
  :ValidIf(function()
      if isSendingNotificationForTTS == true or isSendingNotificationForUI == true then
        return common.responseTimeCalculationFromMobReq(pExpTimeBetweenResp, nil, requestTime)
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
common.Step("Send AlertManeuver with ttsChunks and softButton", AlertManeuver, { 3000, 2000 })
common.Step("Send AlertManeuver with softButton, ttsChunks and onResetTimeout notification for UI.SubtleAlert",
  AlertManeuver, { 13000, 12000, true, false })
common.Step("Send AlertManeuver with softButton, ttsChunks and onResetTimeout notification for TTS.Speak",
  AlertManeuver, { 13000, 12000, false, true })
common.Step("Send AlertManeuver with softButton, ttsChunks and onResetTimeout notification for TTS.Speak and Navigation.SubtleAlert",
  AlertManeuver, { 13000, 12000, true, true })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
