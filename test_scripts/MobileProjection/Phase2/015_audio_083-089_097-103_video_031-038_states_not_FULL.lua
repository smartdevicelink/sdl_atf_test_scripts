---------------------------------------------------------------------------------------------------
-- Issue:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local onHMIStatusData = {}
local testCases = {
  [001] = { t = "NAVIGATION",    m = true,  e = "DEACTIVATE_HMI" },
  [002] = { t = "NAVIGATION",    m = false, e = "DEACTIVATE_HMI" },
  [003] = { t = "PROJECTION",    m = true,  e = "DEACTIVATE_HMI" },
  [004] = { t = "PROJECTION",    m = false, e = "DEACTIVATE_HMI" },
  [005] = { t = "COMMUNICATION", m = true,  e = "DEACTIVATE_HMI" },
  [006] = { t = "COMMUNICATION", m = false, e = "DEACTIVATE_HMI" },
  [007] = { t = "MEDIA",         m = true,  e = "DEACTIVATE_HMI" },
  [008] = { t = "MEDIA",         m = false, e = "DEACTIVATE_HMI" },
  [009] = { t = "DEFAULT",       m = true,  e = "DEACTIVATE_HMI" },
  [010] = { t = "DEFAULT",       m = false, e = "DEACTIVATE_HMI" },
  [011] = { t = "NAVIGATION",    m = true,  e = "AUDIO_SOURCE" },
  [012] = { t = "NAVIGATION",    m = false, e = "AUDIO_SOURCE" },
  [013] = { t = "PROJECTION",    m = true,  e = "AUDIO_SOURCE" },
  [014] = { t = "PROJECTION",    m = false, e = "AUDIO_SOURCE" },
  [015] = { t = "COMMUNICATION", m = true,  e = "AUDIO_SOURCE" },
  [016] = { t = "COMMUNICATION", m = false, e = "AUDIO_SOURCE" },
  [017] = { t = "MEDIA",         m = true,  e = "AUDIO_SOURCE" },
  [018] = { t = "MEDIA",         m = false, e = "AUDIO_SOURCE" },
  [019] = { t = "DEFAULT",       m = true,  e = "AUDIO_SOURCE" },
  [020] = { t = "DEFAULT",       m = false, e = "AUDIO_SOURCE" },
}

--[[ Local Functions ]]
local function sendEvent(pTC, pEvent, pIsActive)
  local count = 1
  if onHMIStatusData.hmiL == "BACKGROUND" then count = 0 end
  local status = common.cloneTable(onHMIStatusData)
  if pIsActive == true then
    status.hmiL = "BACKGROUND"
    status.aSS = "NOT_AUDIBLE"
    status.vSS = "NOT_STREAMABLE"
  end
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = pEvent,
    isActive = pIsActive })
  common.getMobileSession():ExpectNotification("OnHMIStatus", { hmiLevel = status.hmiL })
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, "App1", status.aSS, data.payload.audioStreamingState)
    end)
  :ValidIf(function(_, data)
      return common.checkVideoSS(pTC, "App1", status.vSS, data.payload.videoStreamingState)
    end)
  :Times(count)
  common.wait(500)
end

local function deactivateApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Do(function(_, data)
      onHMIStatusData.hmiL = data.payload.hmiLevel
      onHMIStatusData.aSS = data.payload.audioStreamingState
      onHMIStatusData.vSS = data.payload.videoStreamingState
    end)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. ", event:" .. tc.e .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App Config", common.setAppConfig, { 1, tc.t, tc.m })
  runner.Step("Register App", common.registerApp)
  runner.Step("Activate App", common.activateApp)
  runner.Step("Deactivate App", deactivateApp)
  runner.Step("Send event from HMI isActive: true", sendEvent, { n, tc.e, true })
  runner.Step("Send event from HMI isActive: false", sendEvent, { n, tc.e, false })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
