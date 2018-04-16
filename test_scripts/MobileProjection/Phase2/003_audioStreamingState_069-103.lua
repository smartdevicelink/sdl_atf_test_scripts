---------------------------------------------------------------------------------------------------
-- Issue:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [01] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [02] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [03] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [04] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [05] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [06] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [07] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [08] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [09] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [10] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [11] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [12] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [13] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [14] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [15] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [16] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [17] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [18] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [19] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [20] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [21] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [22] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE", e = "EMBEDDED_NAVI" },
  [23] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE", e = "EMBEDDED_NAVI" },
  [24] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE", e = "EMBEDDED_NAVI" },
  [25] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE", e = "EMBEDDED_NAVI" },
  [26] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "EMBEDDED_NAVI" },
  [27] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE", e = "EMBEDDED_NAVI" },
  [28] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE", e = "EMBEDDED_NAVI" },
  [29] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [30] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [31] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [32] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [33] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [34] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" },
  [35] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" }
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
  runner.Title("TC[" .. common.getTCNum(testCases, n) .. "]: "
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
