---------------------------------------------------------------------------------------------------
-- Issue:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.checkAllValidations = true

--[[ Event Functions ]]
local function activateApp()
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  common.getHMIConnection():ExpectResponse(requestId)
  return "Activation"
end

local function deactivateApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
  return "De-activation"
end

local function deactivateHMI()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "DEACTIVATE_HMI",
    isActive = true })
  return "HMI De-activation"
end

local function activateHMI()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "DEACTIVATE_HMI",
    isActive = false })
  return "HMI Activation"
end

local function exitApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication", {
    appID = common.getHMIAppId(),
    reason = "USER_EXIT" })
  return "User Exit"
end

--[[ Local Variables ]]
local testCases = {
  [001] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [002] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [003] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [004] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [005] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [006] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [007] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [008] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [3] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [009] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [3] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [010] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [011] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [012] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [013] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [014] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [015] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [016] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [017] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [018] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [019] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [020] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [021] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [022] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [023] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [024] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [025] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [026] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [3] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [027] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [3] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [028] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [029] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = activateHMI,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [030] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = activateHMI,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [031] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = activateHMI,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [032] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = activateHMI,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }}
}

--[[ Local Functions ]]
local function doAction(pTC, pSS)
  local event = pSS.e()
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, event, pSS.a, data.payload.audioStreamingState)
    end)
  :ValidIf(function(_, data)
      return common.checkVideoSS(pTC, event, pSS.v, data.payload.videoStreamingState)
    end)
  :ValidIf(function(_, data)
      return common.checkHMILevel(pTC, event, pSS.l, data.payload.hmiLevel)
    end)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. common.getTCNum(testCases, n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App Config", common.setAppConfig, { 1, tc.t, tc.m })
  runner.Step("Register App", common.registerApp)
  for i = 1, #tc.s do
    runner.Step("Action " .. i .. ",hmiLevel:" .. tc.s[i].l, doAction, { n, tc.s[i] })
  end
  -- runner.Step("Activate App:" .. tc.s[1].l, doAction, { n, tc.s[1] })
  -- runner.Step("Deactivate App:" .. tc.s[2].l, doAction, { n, tc.s[2] })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
