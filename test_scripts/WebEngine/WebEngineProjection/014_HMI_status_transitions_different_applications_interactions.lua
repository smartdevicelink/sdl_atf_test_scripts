---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description: Check HMI status transitions of different applications interactions with WEB_VIEW application
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) There are 4 different apps are registered (WEB_VIEW and 3 other):
--   Applications types: WEB_VIEW, PROJECTION, DEFAULT, NAVIGATION
--
-- Sequence:
-- 1) And there is the following sequence of actions:
--    Activation of app1
--    Activation of app2
--    Activation of app3
--    Activation of app4
--    HMI sends PHONE_CALL event (active/inactive)
--    Activation of app2
--    HMI sends EMBEDDED_NAVI event (active/inactive)
--   a. SDL sends end (or not send) 'OnHMIStatus' notification to all apps with appropriate value for
-- 'hmiLevel', 'audioStreamingState' and 'videoStreamingState' parameters
--
-- Particular values depends on app's 'appHMIType', 'isMediaApplication' flag, current app's state
-- and described in 'testCases' table below
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Test Configuration ]]
config.checkAllValidations = true
config.defaultProtocolVersion = 3

--[[ Local Constants ]]
local devices = {
  default = 1,
  webEngine = 2
}

local webViewApp = 1

local testCase = {
  apps = {
    [1] = { type = "WEB_VIEW", isMedia = true, device = devices.webEngine },
    [2] = { type = "PROJECTION", isMedia = false, device = devices.default },
    [3] = { type = "DEFAULT", isMedia = false, device = devices.default },
    [4] = { type = "NAVIGATION", isMedia = true, device = devices.default }
  },
  steps = {
    [1] = {
      action = { event = common.userActions.activateApp, appId = 1 },
      checks = {
        onHmiStatus = {
          [1] = { hmiLvl = "FULL", audio = "AUDIBLE", video = "NOT_STREAMABLE" },
          [2] = { }, -- hmiLvl = "NONE", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
          [3] = { }, -- hmiLvl = "NONE", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
          [4] = { }  -- hmiLvl = "NONE", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
        }
      }
    },
    [2] = {
      action = { event = common.userActions.activateApp, appId = 2 },
      checks = {
        onHmiStatus = {
          [1] = { hmiLvl = "LIMITED", audio = "AUDIBLE", video = "NOT_STREAMABLE" },
          [2] = { hmiLvl = "FULL", audio = "NOT_AUDIBLE", video = "STREAMABLE" },
          [3] = { }, -- hmiLvl = "NONE", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
          [4] = { }  -- hmiLvl = "NONE", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
        }
      }
    },
    [3] = {
      action = { event = common.userActions.activateApp, appId = 3 },
      checks = {
        onHmiStatus = {
          [1] = { }, -- hmiLvl = "LIMITED", audio = "AUDIBLE", video = "NOT_STREAMABLE"
          [2] = { hmiLvl = "LIMITED", audio = "NOT_AUDIBLE", video = "STREAMABLE" },
          [3] = { hmiLvl = "FULL", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
          [4] = { } -- hmiLvl = "NONE", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
        }
      }
    },
    [4] = {
      action = { event = common.userActions.activateApp, appId = 4 },
      checks = {
        onHmiStatus = {
          [1] = { }, -- hmiLvl = "LIMITED", audio = "AUDIBLE", video = "NOT_STREAMABLE"
          [2] = { hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
          [3] = { hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
          [4] = { hmiLvl = "FULL", audio = "AUDIBLE", video = "STREAMABLE" }
        }
      }
    },
    [5] = {
      action = { event = common.userActions.phoneCallStart, appId = "none" },
      checks = {
        onHmiStatus = {
          [1] = { hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
          [2] = { }, -- hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
          [3] = { }, -- hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
          [4] = { hmiLvl = "LIMITED", audio = "NOT_AUDIBLE", video = "STREAMABLE" }
        }
      }
    },
    [6] = {
      action = { event = common.userActions.phoneCallEnd, appId = "none" },
      checks = {
        onHmiStatus = {
          [1] = { hmiLvl = "LIMITED", audio = "AUDIBLE", video = "NOT_STREAMABLE" },
          [2] = { }, -- hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
          [3] = { }, -- hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
          [4] = { hmiLvl = "FULL", audio = "AUDIBLE", video = "STREAMABLE" }
        }
      }
    },
    [7] = {
      action = { event = common.userActions.activateApp, appId = 2 },
      checks = {
        onHmiStatus = {
          [1] = { }, -- hmiLvl = "LIMITED", audio = "AUDIBLE", video = "NOT_STREAMABLE"
          [2] = { hmiLvl = "FULL", audio = "NOT_AUDIBLE", video = "STREAMABLE" },
          [3] = { }, -- hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
          [4] = { hmiLvl = "LIMITED", audio = "AUDIBLE", video = "NOT_STREAMABLE" }
        }
      }
    },
    [8] = {
      action = { event = common.userActions.embeddedNaviActivate, appId = "none" },
      checks = {
        onHmiStatus = {
          [1] = { hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
          [2] = { hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
          [3] = { }, -- hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
          [4] = { hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
        }
      }
    },
    [9] = {
      action = { event = common.userActions.embeddedNaviDeactivate, appId = "none" },
      checks = {
        onHmiStatus = {
          [1] = { hmiLvl = "LIMITED", audio = "AUDIBLE", video = "NOT_STREAMABLE" },
          [2] = { hmiLvl = "FULL", audio = "NOT_AUDIBLE", video = "STREAMABLE" },
          [3] = { }, -- hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE"
          [4] = { hmiLvl = "LIMITED", audio = "AUDIBLE", video = "NOT_STREAMABLE" }
        }
      }
    }
  }
}

local function doAction(pStep)
  pStep.action.event.func(pStep.action.appId)
  for appId, ohsChecks in ipairs(pStep.checks.onHmiStatus) do
    common.checkHMIStatus(pStep.action.event.name, appId, ohsChecks)
  end
end

local function getDeviceName(pDeviceId)
  return pDeviceId == devices.default and "Mobile" or "Web Engine"
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update WS Server Certificate parameters in smartDeviceLink.ini file", common.commentAllCertInIniFile)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT,
  { webViewApp, { testCase.apps[1].type }})
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Connect WebEngine device", common.connectWebEngine, { devices.webEngine, "WS" })
for appId, params in pairs(testCase.apps) do
  common.Step("Set App " .. appId .. " Config", common.setAppConfig, { appId, params.type, params.isMedia })
  common.Step("Register App " .. appId .. " on " .. getDeviceName(params.device), common.registerAppWOPTU,
    { appId, params.device })
end

common.Title("Test")
for i = 1, #testCase.steps do
  common.Step("Action:" .. testCase.steps[i].action.event.name .. " app " .. testCase.steps[i].action.appId, doAction,
    { testCase.steps[i] })
end

common.Title("Postconditions")
common.Step("Clean sessions", common.cleanSessions)
common.Step("Stop SDL", common.postconditions)
