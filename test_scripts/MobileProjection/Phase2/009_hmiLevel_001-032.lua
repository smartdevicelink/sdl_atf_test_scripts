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
  [01] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [02] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [03] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [04] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [05] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [06] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [07] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [08] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [3] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [09] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [3] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [10] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [11] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [12] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [13] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [14] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [15] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [16] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [17] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [18] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [19] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [20] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [21] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [22] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [23] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [24] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [25] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [26] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [3] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [27] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [3] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [28] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [29] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = activateHMI,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [30] = { t = "PROJECTION", m = false, s = {
    [1] = { e = activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = activateHMI,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [31] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = activateHMI,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [32] = { t = "DEFAULT",    m = false, s = {
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
