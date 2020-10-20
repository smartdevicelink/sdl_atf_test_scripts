---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description: Check HMI status transitions of WEB_VIEW application
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) WebEngine App with WEB_VIEW HMI type is registered
-- 3) WebEngine App is in some state
--
-- Sequence:
-- 1) WebEngine App is moving to another state by one of the events:
--    App activation, App deactivation, Deactivation of HMI, User exit
--   a. SDL sends OnHMIStatus notification with appropriate value of 'hmiLevel' parameter
--
-- Particular behavior and value depends on initial state and event, and described in 'testCases' table below
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Test Configuration ]]
config.checkAllValidations = true

--[[ Local Constants ]]
local appSessionId = 1
local webEngineDevice = 1

--[[ Local Functions ]]
local function action(pActionName)
  return common.userActions[pActionName]
end

local function doAction(pExpAppState)
  pExpAppState.event.func()
  common.checkHMIStatus(pExpAppState.event.name, appSessionId, pExpAppState)
end

--[[ Local Variables ]]
local testCases = {
  [001] = { appType = "WEB_VIEW", isMedia = true,  state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" }
  }},
  [002] = { appType = "WEB_VIEW", isMedia = false, state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [003] = { appType = "WEB_VIEW", isMedia = true,  state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateApp"), hmiLvl = "LIMITED",    audio = "AUDIBLE",     video = "NOT_STREAMABLE" }
  }},
  [004] = { appType = "WEB_VIEW", isMedia = false, state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateApp"), hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [005] = { appType = "WEB_VIEW", isMedia = true,  state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateHMI"), hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [006] = { appType = "WEB_VIEW", isMedia = false, state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateHMI"), hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [007] = { appType = "WEB_VIEW", isMedia = true,  state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateApp"), hmiLvl = "LIMITED",    audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [3] = { event = action("deactivateHMI"), hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [008] = { appType = "WEB_VIEW", isMedia = true,  state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [2] = { event = action("exitApp"),       hmiLvl = "NONE",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [009] = { appType = "WEB_VIEW", isMedia = false, state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [2] = { event = action("exitApp"),       hmiLvl = "NONE",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [010] = { appType = "WEB_VIEW", isMedia = true,  state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateApp"), hmiLvl = "LIMITED",    audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [3] = { event = action("exitApp"),       hmiLvl = "NONE",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [011] = { appType = "WEB_VIEW", isMedia = false, state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateApp"), hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [3] = { event = action("exitApp"),       hmiLvl = "NONE",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [012] = { appType = "WEB_VIEW", isMedia = true,  state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateHMI"), hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [3] = { event = action("exitApp"),       hmiLvl = "NONE",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [013] = { appType = "WEB_VIEW", isMedia = false, state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateHMI"), hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [3] = { event = action("exitApp"),       hmiLvl = "NONE",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [014] = { appType = "WEB_VIEW", isMedia = true,  state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateApp"), hmiLvl = "LIMITED",    audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [3] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" }
  }},
  [015] = { appType = "WEB_VIEW", isMedia = false, state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateApp"), hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [3] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }},
  [016] = { appType = "WEB_VIEW", isMedia = true,  state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateHMI"), hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [3] = { event = action("activateHMI"),   hmiLvl = "FULL",       audio = "AUDIBLE",     video = "NOT_STREAMABLE" }
  }},
  [017] = { appType = "WEB_VIEW", isMedia = false, state = {
    [1] = { event = action("activateApp"),   hmiLvl = "FULL",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [2] = { event = action("deactivateHMI"), hmiLvl = "BACKGROUND", audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" },
    [3] = { event = action("activateHMI"),   hmiLvl = "FULL",       audio = "NOT_AUDIBLE", video = "NOT_STREAMABLE" }
  }}
}

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  common.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.appType .. ", isMedia:" .. tostring(tc.isMedia) .. "]")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Update WS Server Certificate parameters in smartDeviceLink.ini file", common.commentAllCertInIniFile)
  common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT, { appSessionId, { tc.appType }})
  common.Step("Start SDL, HMI", common.startWOdeviceConnect)
  common.Step("Connect WebEngine device", common.connectWebEngine, { webEngineDevice, "WS" })
  common.Step("Set App Config", common.setAppConfig, { appSessionId, tc.appType, tc.isMedia })
  common.Step("Register App", common.registerAppWOPTU)

  common.Title("Test")
  for i = 1, #tc.state do
    common.Step("Action:" .. tc.state[i].event.name .. ",hmiLevel:" .. tc.state[i].hmiLvl, doAction, { tc.state[i] })
  end

  common.Title("Postconditions")
  common.Step("Clean sessions", common.cleanSessions)
  common.Step("Stop SDL", common.postconditions)
end
