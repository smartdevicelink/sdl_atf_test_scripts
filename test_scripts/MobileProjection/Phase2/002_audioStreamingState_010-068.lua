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
  [01] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [02] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [03] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [04] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [05] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [06] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [07] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [08] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [09] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [10] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [11] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [12] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [13] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" }},
  [14] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" }},
  [15] = { [1] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE" }, [2] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" }    },
  [16] = { [1] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" }    },
  [17] = { [1] = { t = "NAVIGATION",    m = false, s = "NOT_AUDIBLE" }, [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [18] = { [1] = { t = "NAVIGATION",    m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [19] = { [1] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE" }, [2] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" }    },
  [20] = { [1] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" }    },
  [21] = { [1] = { t = "COMMUNICATION", m = false, s = "NOT_AUDIBLE" }, [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [22] = { [1] = { t = "COMMUNICATION", m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [23] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [24] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [25] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [26] = { [1] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [27] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [28] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [29] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [30] = { [1] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [31] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [32] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [33] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [34] = { [1] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [35] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [36] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [37] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [38] = { [1] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [39] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" }    },
  [40] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" }    },
  [41] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [42] = { [1] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [43] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" }    },
  [44] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" }    },
  [45] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [46] = { [1] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [47] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" }    },
  [48] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" }    },
  [49] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" }    },
  [50] = { [1] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" },     [2] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" }    },
  [51] = { [1] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [52] = { [1] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [53] = { [1] = { t = "PROJECTION",    m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [54] = { [1] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [55] = { [1] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [56] = { [1] = { t = "MEDIA",         m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    },
  [57] = { [1] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" }    },
  [58] = { [1] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "MEDIA",         m = true,  s = "AUDIBLE" }    },
  [59] = { [1] = { t = "DEFAULT",       m = true,  s = "NOT_AUDIBLE" }, [2] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }    }
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
  runner.Title("TC[" .. common.getTCNum(testCases, n) .. "]: "
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
