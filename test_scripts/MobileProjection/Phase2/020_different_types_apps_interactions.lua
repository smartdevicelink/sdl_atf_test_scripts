---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2129
---------------------------------------------------------------------------------------------------
-- Description:
-- In case:
-- 1) There are 4 mobile apps:
--   MEDIA (isMediaApplication = true)
--   PROJECTION (isMediaApplication = false)
--   DEFAULT (isMediaApplication = false)
--   NAVIGATION (isMediaApplication = true)
-- 2) And there is the following sequence of actions:
--   Activation of app1
--   Activation of app2
--   Activation of app3
--   Activation of app4
--   HMI sends PHONE_CALL event (active/inactive)
--   Activation of app2
--   HMI sends EMBEDDED_NAVI event (active/inactive)
-- SDL must:
-- 1) Send (or not send) 'OnHMIStatus' notification to all apps with appropriate value for
-- 'hmiLevel', 'audioStreamingState' and 'videoStreamingState' parameters
-- Particular values depends on app's 'appHMIType', 'isMediaApplication' flag, current app's state
-- and described in 'testCases' table below
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

--[[ Local Variables ]]
local actions = {
  activateApp = {
    name = "Activation",
    func = function(pAppId)
      local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", {
        appID = common.getHMIAppId(pAppId) })
      common.getHMIConnection():ExpectResponse(requestId)
    end
  },
 deactivateApp = {
    name = "De-activation",
    func = function(pAppId)
      common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {
        appID = common.getHMIAppId(pAppId) })
    end
  },
  phoneCallStart = {
    name = "Phone call start",
    func = function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "PHONE_CALL",
        isActive = true })
    end
  },
  phoneCallEnd = {
    name = "Phone call end",
    func = function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "PHONE_CALL",
        isActive = false })
    end
  },
  embeddedNaviActivate = {
    name = "Embedded navigation activation",
    func = function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "EMBEDDED_NAVI",
        isActive = true })
    end
  },
  embeddedNaviDeactivate = {
    name = "Embedded navigation deactivation",
    func = function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "EMBEDDED_NAVI",
        isActive = false })
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
    func = function(pAppId)
      common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication", {
        appID = common.getHMIAppId(),
        reason = "USER_EXIT" })
    end
  }
}

local testCases = {
  [001] = {  -- testcase
    apps = {
      [1] = { t = "MEDIA", m = true },
      [2] = { t = "PROJECTION", m = false },
      [3] = { t = "DEFAULT", m = false },
      [4] = { t = "NAVIGATION", m = true }
    },
    steps = {
      [1] = {
        action = { event = actions.activateApp, appId = 1 },
        checks = {
          ohs = {
            [1] = { hLvl = "FULL", aSS = "AUDIBLE", vSS = "NOT_STREAMABLE" },
            [2] = { }, -- hLvl = "NONE", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
            [3] = { }, -- hLvl = "NONE", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
            [4] = { }  -- hLvl = "NONE", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
          }
        }
      },
      [2] = {
        action = { event = actions.activateApp, appId = 2 },
        checks = {
          ohs = {
            [1] = { hLvl = "LIMITED", aSS = "AUDIBLE", vSS = "NOT_STREAMABLE" },
            [2] = { hLvl = "FULL", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" },
            [3] = { }, -- hLvl = "NONE", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
            [4] = { }  -- hLvl = "NONE", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
          }
        }
      },
      [3] = {
        action = { event = actions.activateApp, appId = 3 },
        checks = {
          ohs = {
            [1] = { }, -- hLvl = "LIMITED", aSS = "AUDIBLE", vSS = "NOT_STREAMABLE"
            [2] = { hLvl = "LIMITED", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" },
            [3] = { hLvl = "FULL", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" },
            [4] = { } -- hLvl = "NONE", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
          }
        }
      },
      [4] = {
        action = { event = actions.activateApp, appId = 4 },
        checks = {
          ohs = {
            [1] = { }, -- hLvl = "LIMITED", aSS = "AUDIBLE", vSS = "NOT_STREAMABLE"
            [2] = { hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" },
            [3] = { hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" },
            [4] = { hLvl = "FULL", aSS = "AUDIBLE", vSS = "STREAMABLE" }
          }
        }
      },
      [5] = {
        action = { event = actions.phoneCallStart, appId = "none" },
        checks = {
          ohs = {
            [1] = { hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" },
            [2] = { }, -- hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
            [3] = { }, -- hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
            [4] = { hLvl = "LIMITED", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" }
          }
        }
      },
      [6] = {
        action = { event = actions.phoneCallEnd, appId = "none" },
        checks = {
          ohs = {
            [1] = { hLvl = "LIMITED", aSS = "AUDIBLE", vSS = "NOT_STREAMABLE" },
            [2] = { }, -- hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
            [3] = { }, -- hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
            [4] = { hLvl = "FULL", aSS = "AUDIBLE", vSS = "STREAMABLE" }
          }
        }
      },
      [7] = {
        action = { event = actions.activateApp, appId = 2 },
        checks = {
          ohs = {
            [1] = { }, -- hLvl = "LIMITED", aSS = "AUDIBLE", vSS = "NOT_STREAMABLE"
            [2] = { hLvl = "FULL", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" },
            [3] = { }, -- hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
            [4] = { hLvl = "LIMITED", aSS = "AUDIBLE", vSS = "NOT_STREAMABLE" }
          }
        }
      },
      [8] = {
        action = { event = actions.embeddedNaviActivate, appId = "none" },
        checks = {
          ohs = {
            [1] = { }, -- hLvl = "LIMITED", aSS = "AUDIBLE", vSS = "NOT_STREAMABLE"
            [2] = { hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" },
            [3] = { }, -- hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
            [4] = { hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE" }
          }
        }
      },
      [9] = {
        action = { event = actions.embeddedNaviDeactivate, appId = "none" },
        checks = {
          ohs = {
            [1] = { }, -- hLvl = "LIMITED", aSS = "AUDIBLE", vSS = "NOT_STREAMABLE"
            [2] = { hLvl = "FULL", aSS = "NOT_AUDIBLE", vSS = "STREAMABLE" },
            [3] = { }, -- hLvl = "BACKGROUND", aSS = "NOT_AUDIBLE", vSS = "NOT_STREAMABLE"
            [4] = { hLvl = "LIMITED", aSS = "AUDIBLE", vSS = "NOT_STREAMABLE" }
          }
        }
      }
    }
  },
}


local function performChecks(pTestCaseNum, pStep, pAppId, pExpectVal)
  local exp = common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
  if pExpectVal.hLvl then
    exp:ValidIf(function(_, data)
        return common.checkAudioSS(pTestCaseNum, pStep.action.event.name, pExpectVal.aSS, data.payload.audioStreamingState)
      end)
    exp:ValidIf(function(_, data)
        return common.checkVideoSS(pTestCaseNum, pStep.action.event.name, pExpectVal.vSS, data.payload.videoStreamingState)
      end)
    exp:ValidIf(function(_, data)
        return common.checkHMILevel(pTestCaseNum, pStep.action.event.name, pExpectVal.hLvl, data.payload.hmiLevel)
      end)
  else
    exp:Times(0)
  end
end

local function doAction(pTestCaseNum, pStep)
  pStep.action.event.func(pStep.action.appId)
  for appId, ohsChecks in ipairs(pStep.checks.ohs) do
    performChecks(pTestCaseNum, pStep, appId, ohsChecks)
  end
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App 1 Config", common.setAppConfig, { 1, tc.apps[1].t, tc.apps[1].m })
  runner.Step("Set App 2 Config", common.setAppConfig, { 2, tc.apps[2].t, tc.apps[2].m })
  runner.Step("Set App 3 Config", common.setAppConfig, { 3, tc.apps[3].t, tc.apps[3].m })
  runner.Step("Set App 4 Config", common.setAppConfig, { 4, tc.apps[4].t, tc.apps[4].m })

  runner.Step("Register App 1", common.registerApp, { 1 })
  runner.Step("Register App 2", common.registerApp, { 2 })
  runner.Step("Register App 3", common.registerApp, { 3 })
  runner.Step("Register App 4", common.registerApp, { 4 })

  for i = 1, #tc.steps do
    runner.Step("Action:" .. tc.steps[i].action.event.name .. " app " .. tc.steps[i].action.appId, doAction, { n, tc.steps[i] })
  end

  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
