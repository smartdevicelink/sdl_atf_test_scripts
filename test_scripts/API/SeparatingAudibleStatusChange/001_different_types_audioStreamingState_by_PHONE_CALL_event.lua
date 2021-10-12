---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0264-Separating-the-change-of-Audible-status-and-the-change-of-HMI-Status.md
---------------------------------------------------------------------------------------------------
-- Description:
-- Check the processing of separating the change of Audible status and the change of HMI Status on 'PHONE_CALL' events
-- In case:
-- 1) Mobile App is in some state
-- 2) Mobile App is moving to another state by 'PHONE_CALL' events:
-- SDL does:
--  - send (or not send) OnHMIStatus notification with appropriate values
--    for 'hmiLevel' and 'audioStreamingState' parameters
-- Particular behavior and value depends on initial state and event, and described in 'testCases' table below
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/SeparatingAudibleStatusChange/common')

--[[ Local Variables ]]
local testCases = {
  [001] = { t = "MEDIA", m = true, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",       a = "AUDIBLE",       v = "NOT_STREAMABLE" },
    [2] = { e = common.events.phoneCallStart,   l = "FULL",       a = "NOT_AUDIBLE",   v = "NOT_STREAMABLE" },
    [3] = { e = common.events.phoneCallEnd,     l = "FULL",       a = "AUDIBLE",       v = "NOT_STREAMABLE" },
    [4] = { e = common.events.deactivateApp,    l = "LIMITED",    a = "AUDIBLE",       v = "NOT_STREAMABLE" },
    [5] = { e = common.events.phoneCallStart,   l = "LIMITED",    a = "NOT_AUDIBLE",   v = "NOT_STREAMABLE" },
    [6] = { e = common.events.phoneCallEnd,     l = "LIMITED",    a = "AUDIBLE",       v = "NOT_STREAMABLE" },
    [7] = { e = common.events.deactivateHMI,    l = "BACKGROUND", a = "NOT_AUDIBLE",   v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd },   -- no changes expected
    [10] = { e = common.events.exitApp,         l = "NONE",       a = "NOT_AUDIBLE",   v = "NOT_STREAMABLE" },
    [11] = { e = common.events.phoneCallStart }, -- no changes expected
    [12] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [002] = { t = "MEDIA", m = false, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",       a = "NOT_AUDIBLE",   v = "NOT_STREAMABLE" },
    [2] = { e = common.events.phoneCallStart }, -- no changes expected
    [3] = { e = common.events.phoneCallEnd },   -- no changes expected
    [4] = { e = common.events.deactivateApp,    l = "BACKGROUND", a = "NOT_AUDIBLE",   v = "NOT_STREAMABLE" },
    [5] = { e = common.events.phoneCallStart }, -- no changes expected
    [6] = { e = common.events.phoneCallEnd },   -- no changes expected
    [7] = { e = common.events.exitApp,          l = "NONE",       a = "NOT_AUDIBLE",   v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [003] = { t = "NAVIGATION", m = true, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "AUDIBLE",      v = "STREAMABLE" },
    [2] = { e = common.events.phoneCallStart,   l = "FULL",        a = "NOT_AUDIBLE",  v = "STREAMABLE" },
    [3] = { e = common.events.phoneCallEnd,     l = "FULL",        a = "AUDIBLE",      v = "STREAMABLE" },
    [4] = { e = common.events.deactivateApp,    l = "LIMITED",     a = "AUDIBLE",      v = "STREAMABLE" },
    [5] = { e = common.events.phoneCallStart,   l = "LIMITED",     a = "NOT_AUDIBLE",  v = "STREAMABLE" },
    [6] = { e = common.events.phoneCallEnd,     l = "LIMITED",     a = "AUDIBLE",      v = "STREAMABLE" },
    [7] = { e = common.events.deactivateHMI,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd },   -- no changes expected
    [10] = { e = common.events.exitApp,         l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [11] = { e = common.events.phoneCallStart }, -- no changes expected
    [12] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [004] = { t = "NAVIGATION", m = false, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "AUDIBLE",      v = "STREAMABLE" },
    [2] = { e = common.events.phoneCallStart,   l = "FULL",        a = "NOT_AUDIBLE",  v = "STREAMABLE" },
    [3] = { e = common.events.phoneCallEnd,     l = "FULL",        a = "AUDIBLE",      v = "STREAMABLE" },
    [4] = { e = common.events.deactivateApp,    l = "LIMITED",     a = "AUDIBLE",      v = "STREAMABLE" },
    [5] = { e = common.events.phoneCallStart,   l = "LIMITED",     a = "NOT_AUDIBLE",  v = "STREAMABLE" },
    [6] = { e = common.events.phoneCallEnd,     l = "LIMITED",     a = "AUDIBLE",      v = "STREAMABLE" },
    [7] = { e = common.events.deactivateHMI,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd },   -- no changes expected
    [10] = { e = common.events.exitApp,         l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [11] = { e = common.events.phoneCallStart }, -- no changes expected
    [12] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [005] = { t = "COMMUNICATION", m = true,  s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [2] = { e = common.events.phoneCallStart,   l = "FULL",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [3] = { e = common.events.phoneCallEnd,     l = "FULL",        a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [4] = { e = common.events.deactivateApp,    l = "LIMITED",     a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [5] = { e = common.events.phoneCallStart,   l = "LIMITED",     a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [6] = { e = common.events.phoneCallEnd,     l = "LIMITED",     a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [7] = { e = common.events.deactivateHMI,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd },   -- no changes expected
    [10] = { e = common.events.exitApp,         l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [11] = { e = common.events.phoneCallStart }, -- no changes expected
    [12] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [006] = { t = "COMMUNICATION", m = false, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [2] = { e = common.events.phoneCallStart,   l = "FULL",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [3] = { e = common.events.phoneCallEnd,     l = "FULL",        a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [4] = { e = common.events.deactivateApp,    l = "LIMITED",     a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [5] = { e = common.events.phoneCallStart,   l = "LIMITED",     a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [6] = { e = common.events.phoneCallEnd,     l = "LIMITED",     a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [7] = { e = common.events.deactivateHMI,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd },   -- no changes expected
    [10] = { e = common.events.exitApp,         l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [11] = { e = common.events.phoneCallStart }, -- no changes expected
    [12] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [007] = { t = "PROJECTION", m = true, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "AUDIBLE",      v = "STREAMABLE" },
    [2] = { e = common.events.phoneCallStart,   l = "FULL",        a = "NOT_AUDIBLE",  v = "STREAMABLE" },
    [3] = { e = common.events.phoneCallEnd,     l = "FULL",        a = "AUDIBLE",      v = "STREAMABLE" },
    [4] = { e = common.events.deactivateApp,    l = "LIMITED",     a = "AUDIBLE",      v = "STREAMABLE" },
    [5] = { e = common.events.phoneCallStart,   l = "LIMITED",     a = "NOT_AUDIBLE",  v = "STREAMABLE" },
    [6] = { e = common.events.phoneCallEnd,     l = "LIMITED",     a = "AUDIBLE",      v = "STREAMABLE" },
    [7] = { e = common.events.deactivateHMI,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd },   -- no changes expected
    [10] = { e = common.events.exitApp,         l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [11] = { e = common.events.phoneCallStart }, -- no changes expected
    [12] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [008] = { t = "PROJECTION", m = false, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "NOT_AUDIBLE",  v = "STREAMABLE" },
    [2] = { e = common.events.phoneCallStart }, -- no changes expected
    [3] = { e = common.events.phoneCallEnd },   -- no changes expected
    [4] = { e = common.events.deactivateApp,    l = "LIMITED",     a = "NOT_AUDIBLE",  v = "STREAMABLE" },
    [5] = { e = common.events.phoneCallStart }, -- no changes expected
    [6] = { e = common.events.phoneCallEnd },   -- no changes expected
    [7] = { e = common.events.deactivateHMI,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd },   -- no changes expected
    [10] = { e = common.events.exitApp,         l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [11] = { e = common.events.phoneCallStart }, -- no changes expected
    [12] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [009] = { t = "DEFAULT", m = true, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [2] = { e = common.events.phoneCallStart,   l = "FULL",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [3] = { e = common.events.phoneCallEnd,     l = "FULL",        a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [4] = { e = common.events.deactivateApp,    l = "LIMITED",     a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [5] = { e = common.events.phoneCallStart,   l = "LIMITED",     a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [6] = { e = common.events.phoneCallEnd,     l = "LIMITED",     a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [7] = { e = common.events.deactivateHMI,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd },   -- no changes expected
    [10] = { e = common.events.exitApp,         l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [11] = { e = common.events.phoneCallStart }, -- no changes expected
    [12] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [010] = { t = "DEFAULT", m = false, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [2] = { e = common.events.phoneCallStart }, -- no changes expected
    [3] = { e = common.events.phoneCallEnd },   -- no changes expected
    [4] = { e = common.events.deactivateApp,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [5] = { e = common.events.phoneCallStart }, -- no changes expected
    [6] = { e = common.events.phoneCallEnd },   -- no changes expected
    [7] = { e = common.events.exitApp,          l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [011] = { t = "REMOTE_CONTROL", m = true, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [2] = { e = common.events.phoneCallStart,   l = "FULL",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [3] = { e = common.events.phoneCallEnd,     l = "FULL",        a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [4] = { e = common.events.deactivateApp,    l = "LIMITED",     a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [5] = { e = common.events.phoneCallStart,   l = "LIMITED",     a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [6] = { e = common.events.phoneCallEnd,     l = "LIMITED",     a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [7] = { e = common.events.deactivateHMI,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd },   -- no changes expected
    [10] = { e = common.events.exitApp,         l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [11] = { e = common.events.phoneCallStart }, -- no changes expected
    [12] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [012] = { t = "REMOTE_CONTROL", m = false, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [2] = { e = common.events.phoneCallStart }, -- no changes expected
    [3] = { e = common.events.phoneCallEnd },   -- no changes expected
    [4] = { e = common.events.deactivateApp,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [5] = { e = common.events.phoneCallStart }, -- no changes expected
    [6] = { e = common.events.phoneCallEnd },   -- no changes expected
    [7] = { e = common.events.exitApp,          l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [014] = { t = "WEB_VIEW", m = true, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [2] = { e = common.events.phoneCallStart,   l = "FULL",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [3] = { e = common.events.phoneCallEnd,     l = "FULL",        a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [4] = { e = common.events.deactivateApp,    l = "LIMITED",     a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [5] = { e = common.events.phoneCallStart,   l = "LIMITED",     a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [6] = { e = common.events.phoneCallEnd,     l = "LIMITED",     a = "AUDIBLE",      v = "NOT_STREAMABLE" },
    [7] = { e = common.events.deactivateHMI,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd },   -- no changes expected
    [10] = { e = common.events.exitApp,         l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [11] = { e = common.events.phoneCallStart }, -- no changes expected
    [12] = { e = common.events.phoneCallEnd }    -- no changes expected
  }},
  [015] = { t = "WEB_VIEW", m = false, s = {
    [1] = { e = common.events.activateApp,      l = "FULL",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [2] = { e = common.events.phoneCallStart }, -- no changes expected
    [3] = { e = common.events.phoneCallEnd },   -- no changes expected
    [4] = { e = common.events.deactivateApp,    l = "BACKGROUND",  a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [5] = { e = common.events.phoneCallStart }, -- no changes expected
    [6] = { e = common.events.phoneCallEnd },   -- no changes expected
    [7] = { e = common.events.exitApp,          l = "NONE",        a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
    [8] = { e = common.events.phoneCallStart }, -- no changes expected
    [9] = { e = common.events.phoneCallEnd }    -- no changes expected
  }}
}

--[[ Local Functions ]]
local function doAction(pTC, pStep)
  common.checkHMIStatus(pTC, pStep.e.name, nil, pStep)
  pStep.e.func()
end

local function updatePreloadedPT(pAppId, pAppHMIType)
  local preloadedTable = common.getPreloadedPT()
  local appId = common.getConfigAppParams(pAppId).fullAppID
  local appPermissions = common.cloneTable(preloadedTable.policy_table.app_policies.default)
  appPermissions.AppHMIType = { pAppHMIType }
  preloadedTable.policy_table.app_policies[appId] = appPermissions
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = common.null
  common.setPreloadedPT(preloadedTable)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  common.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. "]")
  common.Step("Clean environment", common.preconditions)
  if tc.t == "WEB_VIEW" then
    common.Step("Add AppHMIType to preloaded policy table", updatePreloadedPT, { 1, "WEB_VIEW" })
  end
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Set App Config", common.setAppConfig, { 1, tc.t, tc.m })
  common.Step("Register App", common.registerApp)
  for i = 1, #tc.s do
    common.Step("Action:" .. tc.s[i].e.name .. ",hmiLevel:" .. tostring(tc.s[i].l), doAction, { n, tc.s[i] })
  end
  common.Step("Clean sessions", common.cleanSessions)
  common.Step("Stop SDL", common.postconditions)
end
common.Step("Print failed TCs", common.printFailedTCs)
