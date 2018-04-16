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
  [01] = { [1] = { t = "NAVIGATION", m = true,  s = "STREAMABLE" },     [2] = { t = "MEDIA",      m = true,  s = "NOT_STREAMABLE" }},
  [02] = { [1] = { t = "NAVIGATION", m = false, s = "STREAMABLE" },     [2] = { t = "MEDIA",      m = true,  s = "NOT_STREAMABLE" }},
  [03] = { [1] = { t = "PROJECTION", m = true,  s = "STREAMABLE" },     [2] = { t = "MEDIA",      m = true,  s = "NOT_STREAMABLE" }},
  [04] = { [1] = { t = "PROJECTION", m = false, s = "STREAMABLE" },     [2] = { t = "MEDIA",      m = true,  s = "NOT_STREAMABLE" }},
  [05] = { [1] = { t = "NAVIGATION", m = true,  s = "STREAMABLE" },     [2] = { t = "DEFAULT",    m = false, s = "NOT_STREAMABLE" }},
  [06] = { [1] = { t = "NAVIGATION", m = false, s = "STREAMABLE" },     [2] = { t = "DEFAULT",    m = false, s = "NOT_STREAMABLE" }},
  [07] = { [1] = { t = "PROJECTION", m = true,  s = "STREAMABLE" },     [2] = { t = "DEFAULT",    m = false, s = "NOT_STREAMABLE" }},
  [08] = { [1] = { t = "PROJECTION", m = false, s = "STREAMABLE" },     [2] = { t = "DEFAULT",    m = false, s = "NOT_STREAMABLE" }},
  [09] = { [1] = { t = "NAVIGATION", m = true,  s = "NOT_STREAMABLE" }, [2] = { t = "NAVIGATION", m = true,  s = "STREAMABLE" }},
  [10] = { [1] = { t = "NAVIGATION", m = true,  s = "NOT_STREAMABLE" }, [2] = { t = "NAVIGATION", m = false, s = "STREAMABLE" }},
  [11] = { [1] = { t = "NAVIGATION", m = false, s = "NOT_STREAMABLE" }, [2] = { t = "NAVIGATION", m = true,  s = "STREAMABLE" }},
  [12] = { [1] = { t = "NAVIGATION", m = false, s = "NOT_STREAMABLE" }, [2] = { t = "NAVIGATION", m = false, s = "STREAMABLE" }},
  [13] = { [1] = { t = "PROJECTION", m = true,  s = "NOT_STREAMABLE" }, [2] = { t = "NAVIGATION", m = true,  s = "STREAMABLE" }},
  [14] = { [1] = { t = "PROJECTION", m = true,  s = "NOT_STREAMABLE" }, [2] = { t = "NAVIGATION", m = false, s = "STREAMABLE" }},
  [15] = { [1] = { t = "PROJECTION", m = false, s = "NOT_STREAMABLE" }, [2] = { t = "NAVIGATION", m = true,  s = "STREAMABLE" }},
  [16] = { [1] = { t = "PROJECTION", m = false, s = "NOT_STREAMABLE" }, [2] = { t = "NAVIGATION", m = false, s = "STREAMABLE" }},
  [17] = { [1] = { t = "PROJECTION", m = true,  s = "NOT_STREAMABLE" }, [2] = { t = "PROJECTION", m = true,  s = "STREAMABLE" }},
  [18] = { [1] = { t = "PROJECTION", m = true,  s = "NOT_STREAMABLE" }, [2] = { t = "PROJECTION", m = false, s = "STREAMABLE" }},
  [19] = { [1] = { t = "PROJECTION", m = false, s = "NOT_STREAMABLE" }, [2] = { t = "PROJECTION", m = true,  s = "STREAMABLE" }},
  [20] = { [1] = { t = "PROJECTION", m = false, s = "NOT_STREAMABLE" }, [2] = { t = "PROJECTION", m = false, s = "STREAMABLE" }},
  [21] = { [1] = { t = "NAVIGATION", m = true,  s = "NOT_STREAMABLE" }, [2] = { t = "PROJECTION", m = true,  s = "STREAMABLE" }},
  [22] = { [1] = { t = "NAVIGATION", m = true,  s = "NOT_STREAMABLE" }, [2] = { t = "PROJECTION", m = false, s = "STREAMABLE" }},
  [23] = { [1] = { t = "NAVIGATION", m = false, s = "NOT_STREAMABLE" }, [2] = { t = "PROJECTION", m = true,  s = "STREAMABLE" }},
  [24] = { [1] = { t = "NAVIGATION", m = false, s = "NOT_STREAMABLE" }, [2] = { t = "PROJECTION", m = false, s = "STREAMABLE" }}
}

--[[ Local Functions ]]
local function activateApp2(pTC, pVideoSSApp1, pVideoSSApp2)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(2) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(1):ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkVideoSS(pTC, "App1", pVideoSSApp1, data.payload.videoStreamingState)
    end)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkVideoSS(pTC, "App2", pVideoSSApp2, data.payload.videoStreamingState)
    end)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. common.getTCNum(testCases, n) .. "]: "
    .. "App1[hmiType:" .. tc[1].t .. ", isMedia:" .. tostring(tc[1].m) .. "], "
    .. "App2[hmiType:" .. tc[2].t .. ", isMedia:" .. tostring(tc[2].m) .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App 1 Config", common.setAppConfig, { 1, tc[1].t, tc[1].m })
  runner.Step("Set App 2 Config", common.setAppConfig, { 2, tc[2].t, tc[2].m })
  runner.Step("Register App 1", common.registerApp, { 1 })
  runner.Step("Register App 2", common.registerApp, { 2 })
  runner.Step("Activate App 1", common.activateApp, { 1 })
  runner.Step("Activate App 2, videoStates: app1 " ..  tc[1].s .. ", app2 " .. tc[2].s, activateApp2,
    { n, tc[1].s, tc[2].s })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
