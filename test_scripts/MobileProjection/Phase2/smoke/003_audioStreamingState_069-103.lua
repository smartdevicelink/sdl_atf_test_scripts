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
  [073] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "PHONE_CALL" },
  [080] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "EMERGENCY_EVENT" },
  [087] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "AUDIO_SOURCE" },
  [094] = { t = "PROJECTION",    m = true,  s = "AUDIBLE", e = "EMBEDDED_NAVI" },
  [101] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE", e = "DEACTIVATE_HMI" }
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
