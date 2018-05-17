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
  [001] = { [1] = { t = "NAVIGATION", m = false }, [2] = { t = "PROJECTION", m = true }},
  [002] = { [1] = { t = "NAVIGATION", m = false }, [2] = { t = "PROJECTION", m = false }},
  [003] = { [1] = { t = "NAVIGATION", m = true },  [2] = { t = "PROJECTION", m = true }},
  [004] = { [1] = { t = "NAVIGATION", m = true },  [2] = { t = "PROJECTION", m = false }},

  [005] = { [1] = { t = "PROJECTION", m = false }, [2] = { t = "NAVIGATION", m = true }},
  [006] = { [1] = { t = "PROJECTION", m = false }, [2] = { t = "NAVIGATION", m = false }},
  [007] = { [1] = { t = "PROJECTION", m = true },  [2] = { t = "NAVIGATION", m = true }},
  [008] = { [1] = { t = "PROJECTION", m = true },  [2] = { t = "NAVIGATION", m = false }},

  [009] = { [1] = { t = "NAVIGATION", m = false }, [2] = { t = "NAVIGATION", m = false }},
  [010] = { [1] = { t = "NAVIGATION", m = false }, [2] = { t = "NAVIGATION", m = true }},
  [011] = { [1] = { t = "NAVIGATION", m = true },  [2] = { t = "NAVIGATION", m = false }},
  [012] = { [1] = { t = "NAVIGATION", m = true },  [2] = { t = "NAVIGATION", m = true }},

  [013] = { [1] = { t = "PROJECTION", m = false }, [2] = { t = "PROJECTION", m = false }},
  [014] = { [1] = { t = "PROJECTION", m = false }, [2] = { t = "PROJECTION", m = true }},
  [015] = { [1] = { t = "PROJECTION", m = true },  [2] = { t = "PROJECTION", m = false }},
  [016] = { [1] = { t = "PROJECTION", m = true },  [2] = { t = "PROJECTION", m = true }},
}

--[[ Local Functions ]]
local function unregisterApp2()
  local cid = common.getMobileSession(2):SendRPC("UnregisterAppInterface", {})
  common.getMobileSession(2):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", {
    appID = common.getHMIAppId(2),
    unexpectedDisconnect = false
  })
  common.getMobileSession(1):ExpectNotification("OnHMIStatus")
  :Times(0)
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
  runner.Step("Activate App 2", common.activateApp, { 2 })
  runner.Step("Unregister App 2", unregisterApp2)
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
