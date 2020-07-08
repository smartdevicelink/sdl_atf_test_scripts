---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description: Check audioStreamingState transitions of WEB_VIEW application on HMI events
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) WebEngine App with WEB_VIEW HMI type is registered
-- 3) WebEngine App is audio source ('audioStreamingState' = AUDIBLE)
--
-- Sequence:
-- 1) One of the events below is received from HMI within 'BC.OnEventChanged' notification:
--    PHONE_CALL, EMERGENCY_EVENT, AUDIO_SOURCE, EMBEDDED_NAVI
--   a. SDL sends OnHMIStatus notification with 'audioStreamingState' = NOT_AUDIBLE
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Test Configuration ]]
config.checkAllValidations = true

--[[ Local Constants ]]
local appSessionId = 1
local webEngineDevice = 1

--[[ Local Variables ]]
local testCases = {
  [001] = { appType = "WEB_VIEW", isMedia = true, audioState = "NOT_AUDIBLE", event = "PHONE_CALL" },
  [002] = { appType = "WEB_VIEW", isMedia = true, audioState = "NOT_AUDIBLE", event = "EMERGENCY_EVENT" },
  [003] = { appType = "WEB_VIEW", isMedia = true, audioState = "NOT_AUDIBLE", event = "AUDIO_SOURCE" },
  [004] = { appType = "WEB_VIEW", isMedia = true, audioState = "NOT_AUDIBLE", event = "EMBEDDED_NAVI" }
}

--[[ Local Functions ]]
local function sendEvent(pEvent, pAudioSS)
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = pEvent,
    isActive = true })
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkAudioSS("App1", pAudioSS, data.payload.audioStreamingState)
    end)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  common.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.appType .. ", isMedia:" .. tostring(tc.isMedia) .. ", event:" .. tc.event .. "]")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Update WS Server Certificate parameters in smartDeviceLink.ini file", common.commentAllCertInIniFile)
  common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT, { appSessionId, { tc.appType }})
  common.Step("Start SDL, HMI", common.startWOdeviceConnect)
  common.Step("Connect WebEngine device", common.connectWebEngine, { webEngineDevice, "WS" })
  common.Step("Set App Config", common.setAppConfig, { appSessionId, tc.appType, tc.isMedia })
  common.Step("Register App", common.registerAppWOPTU)
  common.Step("Activate App", common.activateApp)

  common.Title("Test")
  common.Step("Send event from HMI: " .. tc.event, sendEvent, { tc.event, tc.audioState })

  common.Title("Postconditions")
  common.Step("Clean sessions", common.cleanSessions)
  common.Step("Stop SDL", common.postconditions)
end
