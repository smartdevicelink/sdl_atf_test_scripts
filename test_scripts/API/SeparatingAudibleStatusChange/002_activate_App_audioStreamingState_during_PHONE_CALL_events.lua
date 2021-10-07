---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0264-Separating-the-change-of-Audible-status-and-the-change-of-HMI-Status.md
---------------------------------------------------------------------------------------------------
-- Description:
-- Check the processing of separating the change of Audible status and the change of HMI Status in case
--  second App is activated during 'PHONE_CALL' events
-- In case:
-- 1) Mobile App1 and App2 are registered
-- 2) Mobile App1 is activated
-- 3) Mobile App2 is activated
-- 4) Mobile Apps are moving to another state by 'PHONE_CALL' event (isActive = true) from HMI
-- 5) Mobile App1 is activated
-- 6) Mobile Apps are moving to another state by 'PHONE_CALL' event (isActive = false) from HMI
-- SDL does:
--  - send OnHMIStatus notification with appropriate values for 'audioStreamingState' parameters
-- Particular behavior and value depends on initial state and event, and described in 'testCases' table below
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/SeparatingAudibleStatusChange/common')

--[[ Local Variables ]]
local testCase = {
  [001] = {
    apps = {
      [1] = { t = "DEFAULT", m = false },
      [2] = { t = "MEDIA",   m = true  }
    },
    steps = {
      [1] = {
        action = { event = common.events.activateApp, appId = 1 },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
            [2] = { } -- l = "NONE",  a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" - no changes expected
          }
        }
      },
      [2] = {
        action = { event = common.events.activateApp, appId = 2 },
        checks = {
          onHmiStatus = {
            [1] = { l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
            [2] = { l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" }
          }
        }
      },
      [3] = {
        action = { event = common.events.phoneCallStart },
        checks = {
          onHmiStatus = {
            [1] = { }, -- l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" - no changes expected
            [2] = { l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
          }
        }
      },
      [4] = {
        action = { event = common.events.activateApp, appId = 1 },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
            [2] = { l = "LIMITED",    a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
          }
        }
      },
      [5] = {
        action = { event = common.events.phoneCallEnd },
        checks = {
          onHmiStatus = {
            [1] = { }, -- l = "FULL", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" - no changes expected
            [2] = { l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" }
          }
        }
      }
    }
  },
  [002] = {
    apps = {
      [1] = { t = "MEDIA",      m = true },
      [2] = { t = "NAVIGATION", m = true }
    },
    steps = {
      [1] = {
        action = { event = common.events.activateApp },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE" },
            [2] = { } -- l = "NONE",  a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" - no changes expected
          }
        }
      },
      [2] = {
        action = { event = common.events.activateApp, appId = 2 },
        checks = {
          onHmiStatus = {
            [1] = { l = "LIMITED",    a = "AUDIBLE",     v = "NOT_STREAMABLE" },
            [2] = { l = "FULL",       a = "AUDIBLE",     v = "STREAMABLE" }
          }
        }
      },
      [3] = {
        action = { event = common.events.phoneCallStart },
        checks = {
          onHmiStatus = {
            [1] = { l = "LIMITED",    a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
            [2] = { l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
          }
        }
      },
      [4] = {
        action = { event = common.events.activateApp, appId = 1 },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
            [2] = { l = "LIMITED",    a = "NOT_AUDIBLE", v = "STREAMABLE" }
          }
        }
      },
      [5] = {
        action = { event = common.events.phoneCallEnd },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",       a = "AUDIBLE",     v = "NOT_STREAMABLE"},
            [2] = { l = "LIMITED",    a = "AUDIBLE",     v = "STREAMABLE" }
          }
        }
      }
    }
  },
  [003] = {
    apps = {
      [1] = { t = "DEFAULT",    m = false },
      [2] = { t = "PROJECTION", m = false }
    },
    steps = {
      [1] = {
        action = { event = common.events.activateApp, appId = 1 },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",       a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
            [2] = { } -- l = "NONE",  a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" - no changes expected
          }
        }
      },
      [2] = {
        action = { event = common.events.activateApp, appId = 2 },
        checks = {
          onHmiStatus = {
            [1] = { l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" },
            [2] = { l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" }
          }
        }
      },
      [3] = {
        action = { event = common.events.phoneCallStart },
        checks = {
          onHmiStatus = {
            [1] = { }, --l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" , - no changes expected
            [2] = { }  --l = "FULL",       a = "NOT_AUDIBLE", v = "STREAMABLE" } - no changes expected
          }
        }
      },
      [4] = {
        action = { event = common.events.activateApp, appId = 1 },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",       a = "NOT_AUDIBLE",   v = "NOT_STREAMABLE" },
            [2] = { l = "LIMITED",    a = "NOT_AUDIBLE",   v = "STREAMABLE" }
          }
        }
      },
      [5] = {
        action = { event = common.events.phoneCallEnd },
        checks = {
          onHmiStatus = {
            [1] = { }, --l = "FULL",    a = "NOT_AUDIBLE", v = "NOT_STREAMABLE"}, - no changes expected
            [2] = { }  --l = "LIMITED", a = "NOT_AUDIBLE", v = "STREAMABLE" } - no changes expected
          }
        }
      }
    }
  },
  [004] = {
    apps = {
      [1] = { t = "NAVIGATION",      m = false },
      [2] = { t = "COMMUNICATION",   m = false }
    },
    steps = {
      [1] = {
        action = { event = common.events.activateApp, appId = 1 },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",         a = "AUDIBLE",     v = "STREAMABLE" },
            [2] = { } -- l = "NONE",    a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" - no changes expected
          }
        }
      },
      [2] = {
        action = { event = common.events.activateApp, appId = 2 },
        checks = {
          onHmiStatus = {
            [1] = { l = "LIMITED",      a = "AUDIBLE",     v = "STREAMABLE" },
            [2] = { l = "FULL",         a = "AUDIBLE",     v = "NOT_STREAMABLE" }
          }
        }
      },
      [3] = {
        action = { event = common.events.phoneCallStart },
        checks = {
          onHmiStatus = {
            [1] = { l = "LIMITED",      a = "NOT_AUDIBLE", v = "STREAMABLE" },
            [2] = { l = "FULL",         a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
          }
        }
      },
      [4] = {
        action = { event = common.events.activateApp, appId = 1 },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",         a = "NOT_AUDIBLE", v = "STREAMABLE" },
            [2] = { l = "LIMITED",      a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" }
          }
        }
      },
      [5] = {
        action = { event = common.events.phoneCallEnd },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",         a = "AUDIBLE",     v = "STREAMABLE"},
            [2] = { l = "LIMITED",      a = "AUDIBLE",     v = "NOT_STREAMABLE" }
          }
        }
      }
    }
  },
  [005] = {
    apps = {
      [1] = { t = "MEDIA",      m = true },
      [2] = { t = "MEDIA",      m = true }
    },
    steps = {
      [1] = {
        action = { event = common.events.activateApp, appId = 1 },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",       a = "AUDIBLE", v = "NOT_STREAMABLE" },
            [2] = { } -- l = "NONE",  a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" - no changes expected
          }
        }
      },
      [2] = {
        action = { event = common.events.activateApp, appId = 2 },
        checks = {
          onHmiStatus = {
            [1] = { l = "BACKGROUND", a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
            [2] = { l = "FULL",       a = "AUDIBLE",      v = "NOT_STREAMABLE" }
          }
        }
      },
      [3] = {
        action = { event = common.events.phoneCallStart },
        checks = {
          onHmiStatus = {
            [1] = { }, --l = "BACKGROUND", a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" - no changes expected
            [2] = { l = "FULL",       a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" }
          }
        }
      },
      [4] = {
        action = { event = common.events.activateApp, appId = 1 },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",       a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" },
            [2] = { l = "BACKGROUND", a = "NOT_AUDIBLE",  v = "NOT_STREAMABLE" }
          }
        }
      },
      [5] = {
        action = { event = common.events.phoneCallEnd },
        checks = {
          onHmiStatus = {
            [1] = { l = "FULL",       a = "AUDIBLE",      v = "NOT_STREAMABLE" },
            [2] = { } -- l = "BACKGROUND", a = "NOT_AUDIBLE", v = "NOT_STREAMABLE" - no changes expected
          }
        }
      }
    }
  }
}

--[[ Local Functions ]]
local function doAction(pTC, pStep)
  for appId, ohsChecks in ipairs(pStep.checks.onHmiStatus) do
    common.checkHMIStatus(pTC, pStep.action.event.name, appId, ohsChecks)
  end
  pStep.action.event.func(pStep.action.appId)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCase) do
  common.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "App1[hmiType:" .. tc.apps[1].t .. ", isMedia:" .. tostring(tc.apps[1].m) .. "], "
    .. "App2[hmiType:" .. tc.apps[2].t .. ", isMedia:" .. tostring(tc.apps[2].m) .. "]")
  common.Title("Preconditions")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  for appId, params in pairs(tc.apps) do
    common.Step("Set App " .. appId .. " Config", common.setAppConfig, { appId, params.t, params.m })
    common.Step("Register App " .. appId, common.registerApp, { appId })
  end

  common.Title("Test")
  for i = 1, #tc.steps do
    common.Step("Action:" .. tc.steps[i].action.event.name .. " app " .. tostring(tc.steps[i].action.appId), doAction,
      { n, tc.steps[i] })
  end

  common.Title("Postconditions")
  common.Step("Clean sessions", common.cleanSessions)
  common.Step("Stop SDL", common.postconditions)
end
common.Step("Print failed TCs", common.printFailedTCs)
