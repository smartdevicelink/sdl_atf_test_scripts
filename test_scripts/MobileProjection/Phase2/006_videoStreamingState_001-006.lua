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
  [001] = { t = "MEDIA",      m = true,  s = "NOT_STREAMABLE" },
  [002] = { t = "DEFAULT",    m = false, s = "NOT_STREAMABLE" },
  [003] = { t = "NAVIGATION", m = true,  s = "STREAMABLE" },
  [004] = { t = "NAVIGATION", m = false, s = "STREAMABLE" },
  [005] = { t = "PROJECTION", m = true,  s = "STREAMABLE" },
  [006] = { t = "PROJECTION", m = false, s = "STREAMABLE" }
}

--[[ Local Functions ]]
local function activateApp(pTC, pVideoSS)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkVideoSS(pTC, "App1", pVideoSS, data.payload.videoStreamingState)
    end)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App Config", common.setAppConfig, { 1, tc.t, tc.m })
  runner.Step("Register App", common.registerApp)
  runner.Step("Activate App, videoState:" .. tc.s, activateApp, { n, tc.s })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
