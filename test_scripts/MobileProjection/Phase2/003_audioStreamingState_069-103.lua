---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2129
---------------------------------------------------------------------------------------------------
-- Description:
-- In case:
-- 1) Mobile app is audio source ('audioStreamingState' = AUDIBLE)
-- 2) One of the event below is received from HMI within 'BC.OnEventChanged' notification:
--   PHONE_CALL, EMERGENCY_EVENT, AUDIO_SOURCE, EMBEDDED_NAVI, DEACTIVATE_HMI
-- SDL must:
-- 1) Send OnHMIStatus notification with 'audioStreamingState' = NOT_AUDIBLE
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [069] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [070] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [071] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [072] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [073] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [074] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [075] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [076] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [077] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [078] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [079] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [080] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [081] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [082] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [083] = { t = "NAVIGATION",    m = false, s = "AUDIBLE",     e = "AUDIO_SOURCE" },
  [084] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [085] = { t = "COMMUNICATION", m = false, s = "AUDIBLE",     e = "AUDIO_SOURCE" },
  [086] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [087] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [088] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [089] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [090] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE", e = "EMBEDDED_NAVI" },
  [091] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE", e = "EMBEDDED_NAVI" },
  [092] = { t = "COMMUNICATION", m = false, s = "AUDIBLE",     e = "EMBEDDED_NAVI" },
  [093] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE",     e = "EMBEDDED_NAVI" },
  [094] = { t = "PROJECTION",    m = true,  s = "AUDIBLE",     e = "EMBEDDED_NAVI" },
  [095] = { t = "MEDIA",         m = true,  s = "AUDIBLE",     e = "EMBEDDED_NAVI" },
  [096] = { t = "DEFAULT",       m = true,  s = "AUDIBLE",     e = "EMBEDDED_NAVI" },
  [097] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [098] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [099] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [100] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [101] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [102] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [103] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" }
}

--[[ Local Functions ]]
local function sendEvent(pTC, pEvent, pAudioSS)
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = pEvent,
    isActive = true })
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, "App1", pAudioSS, data.payload.audioStreamingState)
    end)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. ", event:" .. tc.e .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App Config", common.setAppConfig, { 1, tc.t, tc.m })
  runner.Step("Register App", common.registerApp)
  runner.Step("Activate App", common.activateApp)
  runner.Step("Send event from HMI: " .. tc.e, sendEvent, { n, tc.e, tc.s })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
