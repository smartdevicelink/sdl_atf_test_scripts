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
local action = {
  activateApp = {
    name = "Activation",
    func = function()
      local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", {
        appID = common.getHMIAppId() })
      common.getHMIConnection():ExpectResponse(requestId)
    end
  },
 deactivateApp = {
    name = "De-activation",
    func = function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {
        appID = common.getHMIAppId() })
    end
  },
  deactivateHMI = {
    name = "HMI De-activation",
    func = function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "DEACTIVATE_HMI",
        isActive = true })
    end
  },
  activateHMI = {
    name = "HMI Activation",
    func = function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "DEACTIVATE_HMI",
        isActive = false })
    end
  },
  exitApp = {
    name = "User Exit",
    func = function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication", {
        appID = common.getHMIAppId(),
        reason = "USER_EXIT" })
    end
  }
}

--[[ Local Variables ]]
local testCases = {
  [001] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [002] = { t = "PROJECTION", m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [003] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [004] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [005] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [006] = { t = "PROJECTION", m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [007] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [008] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [3] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [009] = { t = "PROJECTION", m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [3] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [010] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [011] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [012] = { t = "PROJECTION", m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [013] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [014] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [015] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [016] = { t = "PROJECTION", m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [017] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [018] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [019] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [3] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [020] = { t = "PROJECTION", m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [3] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [021] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [022] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [023] = { t = "PROJECTION", m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [024] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [025] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = action.exitApp,       l = "NONE",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }},
  [026] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [3] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [027] = { t = "PROJECTION", m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [3] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [028] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = action.deactivateApp, l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [029] = { t = "MEDIA",      m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = action.activateHMI,   l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" }
  }},
  [030] = { t = "PROJECTION", m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = action.activateHMI,   l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
  }},
  [031] = { t = "NAVIGATION", m = true,  s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = action.activateHMI,   l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" }
  }},
  [032] = { t = "DEFAULT",    m = false, s = {
    [1] = { e = action.activateApp,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [2] = { e = action.deactivateHMI, l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
    [3] = { e = action.activateHMI,   l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
  }}
}

--[[ Local Functions ]]
local function doAction(pTC, pSS)
  pSS.e.func()
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, pSS.e.name, pSS.a, data.payload.audioStreamingState)
    end)
  :ValidIf(function(_, data)
      return common.checkVideoSS(pTC, pSS.e.name, pSS.v, data.payload.videoStreamingState)
    end)
  :ValidIf(function(_, data)
      return common.checkHMILevel(pTC, pSS.e.name, pSS.l, data.payload.hmiLevel)
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
  for i = 1, #tc.s do
    runner.Step("Action:" .. tc.s[i].e.name .. ",hmiLevel:" .. tc.s[i].l, doAction, { n, tc.s[i] })
  end
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
