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
  [010] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [011] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [012] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [013] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [014] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [015] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [016] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [017] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [018] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [019] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [020] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [021] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [022] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [023] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [024] = { [1] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE" }, [2] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" }    },
  [025] = { [1] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" }    },
  [026] = { [1] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE" }, [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [027] = { [1] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [028] = { [1] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE" }, [2] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" }    },
  [029] = { [1] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" }    },
  [030] = { [1] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE" }, [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [031] = { [1] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [032] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [033] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [034] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [035] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [036] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [037] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [038] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [039] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [040] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [041] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [042] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [043] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [044] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [045] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [046] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [047] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [048] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" }    },
  [049] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" }    },
  [050] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [051] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [052] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" }    },
  [053] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" }    },
  [054] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [055] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [056] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" }    },
  [057] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" }    },
  [058] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [059] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [060] = { [1] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [061] = { [1] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [062] = { [1] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [063] = { [1] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [064] = { [1] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [065] = { [1] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [066] = { [1] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [067] = { [1] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [068] = { [1] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    }
}

--[[ Local Functions ]]
local function activateApp2(pTC, pAudioSSApp1, pAudioSSApp2)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(2) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(1):ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, "App1", pAudioSSApp1, data.payload.audioStreamingState)
    end)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, "App2", pAudioSSApp2, data.payload.audioStreamingState)
    end)
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
  runner.Step("Register App 2", common.registerApp, { 2 })
  runner.Step("Activate App 1", common.activateApp, { 1 })
  runner.Step("Activate App 2, audioStates: app1 " ..  tc[1].s .. ", app2 " .. tc[2].s, activateApp2,
    { n, tc[1].s, tc[2].s })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
