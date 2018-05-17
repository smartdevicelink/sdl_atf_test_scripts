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
  [001] = { [1] = { t = "MEDIA",   m = false }, [2] = { t = "NAVIGATION", m = false }},
  [002] = { [1] = { t = "DEFAULT", m = false }, [2] = { t = "NAVIGATION", m = false }},
  [003] = { [1] = { t = "MEDIA",   m = false }, [2] = { t = "NAVIGATION", m = true }},
  [004] = { [1] = { t = "DEFAULT", m = false }, [2] = { t = "NAVIGATION", m = true }},
  [005] = { [1] = { t = "MEDIA",   m = false }, [2] = { t = "PROJECTION", m = false }},
  [006] = { [1] = { t = "DEFAULT", m = false }, [2] = { t = "PROJECTION", m = false }},
  [007] = { [1] = { t = "MEDIA",   m = false }, [2] = { t = "PROJECTION", m = true }},
  [008] = { [1] = { t = "DEFAULT", m = false }, [2] = { t = "PROJECTION", m = true }},
}

--[[ Local Functions ]]
local function activateApp2()
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(2) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" })
  common.getMobileSession(1):ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function setApp1ToBACKGROUND()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnHMIStatus", {
    hmiLevel = "BACKGROUND",
    systemContext = "MAIN",
    audioStreamingState = "NOT_AUDIBLE",
    videoStreamingState = "NOT_STREAMABLE"
  })
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
  runner.Step("Set App 1 to BACKGROUND", setApp1ToBACKGROUND)
  runner.Step("Activate App 2", activateApp2)
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
