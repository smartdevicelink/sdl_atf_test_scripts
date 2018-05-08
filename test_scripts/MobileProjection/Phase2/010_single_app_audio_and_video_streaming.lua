---------------------------------------------------------------------------------------------------
-- Issue:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

--[[ Local Variables ]]
local testCases = {
  [001] = { t = "PROJECTION", m = true },
  [002] = { t = "NAVIGATION", m = true },
}

--[[ Local Functions ]]
local function appStartAudioStreaming()
  common.getMobileSession():StartService(10)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession():StartStreaming(10,"files/Kalimba.mp3")
          common.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = true })
        end)
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function appStartVideoStreaming()
  common.getMobileSession():StartService(11)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartStream")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession():StartStreaming(11, "files/Wildlife.wmv")
          common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
        end)
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function appStopStreaming()
  common.getMobileSession():StopStreaming("files/Kalimba.mp3")
  common.getMobileSession():StopStreaming("files/Wildlife.wmv")
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App Config", common.setAppConfig, { 1, tc.t, tc.m })
  runner.Step("Register App", common.registerApp, { 1 })
  runner.Step("Activate App", common.activateApp, { 1 })
  runner.Step("App starts Audio streaming", appStartAudioStreaming)
  runner.Step("App starts Video streaming", appStartVideoStreaming)
  runner.Step("App stops streaming", appStopStreaming)
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
