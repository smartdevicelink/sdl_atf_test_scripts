---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2129
---------------------------------------------------------------------------------------------------
-- Description:
-- In case:
-- 1) Mobile app is video source ('videoStreamingState' = STREAMABLE)
-- 2) One of the event below is received from HMI within 'BC.OnEventChanged' notification:
--   DEACTIVATE_HMI, AUDIO_SOURCE, EMBEDDED_NAVI
-- SDL must:
-- 1) Send OnHMIStatus notification with 'videoStreamingState' = NOT_STREAMABLE
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [031] = { t = "NAVIGATION", m = true,  s = "NOT_STREAMABLE", e = "DEACTIVATE_HMI" },
  [032] = { t = "NAVIGATION", m = false, s = "NOT_STREAMABLE", e = "DEACTIVATE_HMI" },
  [033] = { t = "PROJECTION", m = true,  s = "NOT_STREAMABLE", e = "DEACTIVATE_HMI" },
  [034] = { t = "PROJECTION", m = false, s = "NOT_STREAMABLE", e = "DEACTIVATE_HMI" },
  [035] = { t = "NAVIGATION", m = true,  s = "STREAMABLE", e = "AUDIO_SOURCE" },
  [036] = { t = "NAVIGATION", m = false, s = "STREAMABLE", e = "AUDIO_SOURCE" },
  [037] = { t = "PROJECTION", m = true,  s = "STREAMABLE", e = "AUDIO_SOURCE" },
  [038] = { t = "PROJECTION", m = false, s = "STREAMABLE", e = "AUDIO_SOURCE" },
  [039] = { t = "NAVIGATION", m = true,  s = "NOT_STREAMABLE", e = "EMBEDDED_NAVI" },
  [040] = { t = "NAVIGATION", m = false, s = "NOT_STREAMABLE", e = "EMBEDDED_NAVI" },
  [041] = { t = "PROJECTION", m = true,  s = "NOT_STREAMABLE", e = "EMBEDDED_NAVI" },
  [042] = { t = "PROJECTION", m = false, s = "NOT_STREAMABLE", e = "EMBEDDED_NAVI" }
}

--[[ Local Functions ]]
local function sendEvent(pTC, pEvent, pVideoSS)
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = pEvent,
    isActive = true })
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkVideoSS(pTC, "App1", pVideoSS, data.payload.videoStreamingState)
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
