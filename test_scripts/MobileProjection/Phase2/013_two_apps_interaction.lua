---------------------------------------------------------------------------------------------------
-- Issue:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

--[[ Local Variables ]]
local testCases = {
  [001] = {
    [1] = { t = "PROJECTION", m = true }, [2] = { t = "PROJECTION", m = false },
    ohs1_1 = { l = "LIMITED",    sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" },
    ohs1_2 = { l = "LIMITED",    sc = "MAIN", aSS = "AUDIBLE",     vSS = "NOT_STREAMABLE" },
    ohs2_1 = { l = "FULL",       sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" }
  },
  [002] = {
    [1] = { t = "PROJECTION", m = true }, [2] = { t = "NAVIGATION", m = false },
    ohs1_1 = { l = "LIMITED",    sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" },
    ohs1_2 = { l = "LIMITED",    sc = "MAIN", aSS = "AUDIBLE",     vSS = "NOT_STREAMABLE" },
    ohs2_1 = { l = "FULL",       sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" }
  },
  [003] = {
    [1] = { t = "PROJECTION", m = false }, [2] = { t = "PROJECTION", m = false },
    ohs1_1 = { l = "LIMITED",    sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" },
    ohs1_2 = { l = "BACKGROUND", sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" },
    ohs2_1 = { l = "FULL",       sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" }
  },
  [004] = {
    [1] = { t = "PROJECTION", m = false }, [2] = { t = "PROJECTION", m = true },
    ohs1_1 = { l = "LIMITED",    sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" },
    ohs1_2 = { l = "BACKGROUND", sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" },
    ohs2_1 = { l = "FULL",       sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" }
  },
  [005] = {
    [1] = { t = "PROJECTION", m = false }, [2] = { t = "NAVIGATION", m = false },
    ohs1_1 = { l = "LIMITED",    sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" },
    ohs1_2 = { l = "BACKGROUND", sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" },
    ohs2_1 = { l = "FULL",       sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" }
  },
  [006] = {
    [1] = { t = "NAVIGATION", m = false }, [2] = { t = "PROJECTION", m = false },
    ohs1_1 = { l = "LIMITED",    sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" },
    ohs1_2 = { l = "LIMITED",    sc = "MAIN", aSS = "AUDIBLE",     vSS = "NOT_STREAMABLE" },
    ohs2_1 = { l = "FULL",       sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" }
  },
  [007] = {
    [1] = { t = "NAVIGATION", m = false }, [2] = { t = "PROJECTION", m = true },
    ohs1_1 = { l = "LIMITED",    sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" },
    ohs1_2 = { l = "LIMITED",    sc = "MAIN", aSS = "AUDIBLE",     vSS = "NOT_STREAMABLE" },
    ohs2_1 = { l = "FULL",       sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" }
  },
  [008] = {
    [1] = { t = "PROJECTION", m = true }, [2] = { t = "PROJECTION", m = true },
    ohs1_1 = { l = "LIMITED",    sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" },
    ohs1_2 = { l = "BACKGROUND", sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" },
    ohs2_1 = { l = "FULL",       sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" }
  },
  [009] = {
    [1] = { t = "NAVIGATION", m = false }, [2] = { t = "NAVIGATION", m = false },
    ohs1_1 = { l = "LIMITED",    sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" },
    ohs1_2 = { l = "BACKGROUND", sc = "MAIN", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" },
    ohs2_1 = { l = "FULL",       sc = "MAIN", aSS = "AUDIBLE",     vSS = "STREAMABLE" }
  }
}

--[[ Local Functions ]]
local function deactivateApp(pApp1OHS)
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {
    appID = common.getHMIAppId(1)
  })
  common.getMobileSession(1):ExpectNotification("OnHMIStatus", {
    hmiLevel = pApp1OHS.l,
    systemContext = pApp1OHS.sc,
    audioStreamingState = pApp1OHS.aSS,
    videoStreamingState = pApp1OHS.vSS
  })
end

local function activateApp(pApp1OHS, pApp2OHS)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(2) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus", {
    hmiLevel = pApp2OHS.l,
    systemContext = pApp2OHS.sc,
    audioStreamingState = pApp2OHS.aSS,
    videoStreamingState = pApp2OHS.vSS
  })
  common.getMobileSession(1):ExpectNotification("OnHMIStatus", {
    hmiLevel = pApp1OHS.l,
    systemContext = pApp1OHS.sc,
    audioStreamingState = pApp1OHS.aSS,
    videoStreamingState = pApp1OHS.vSS
  })
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "App1[hmiType:" .. tc[1].t .. ", isMedia:" .. tostring(tc[1].m) .. "], "
    .. "App2[hmiType:" .. tc[2].t .. ", isMedia:" .. tostring(tc[2].m) .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App 1 Config", common.setAppConfig, { 1, tc[1].t, tc[1].m })
  runner.Step("Set App 2 Config", common.setAppConfig, { 2, tc[2].t, tc[2].m })
  runner.Step("Register App 1", common.registerApp, { 1 })
  runner.Step("Activate App 1", common.activateApp, { 1 })
  runner.Step("Register App 2", common.registerApp, { 2 })
  runner.Step("Deactivate App 1", deactivateApp, { tc.ohs1_1 })
  runner.Step("Activate App 2", activateApp, { tc.ohs1_2, tc.ohs2_1 })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
