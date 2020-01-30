---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3165
---------------------------------------------------------------------------------------------------
-- Description:
-- Verify that the HMI status does not change from BACKGROUND to NONE when the SDL receives OnEventChanged with AudioSource: True
-- In case:
-- 1) There are 2 mobile apps registered: Media and PROJECTION
-- 2) Mobile app1 is activated
-- 3) Mobile app2 is activated
-- 4) App2 starts audio streaming
-- 5) HMI sends 'BC.OnExitApplication' (USER_EXIT) for app2
-- SDL must:
-- 1) Start service successful
-- 2) Process streaming from mobile
-- 3) Send 'OnHMIStatus' notification to app2 with 'hmiLevel' = NONE
-- 4) HMI sends 'BC.OnEventChanged' ( eventName = AUDIO_SOURCE, isActive = true)
-- 5) HMI does not send 'OnHMIStatus' notification to Apps
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [001] = { [1] = { t = "MEDIA", m = true }, [2] = { t = "PROJECTION", m = true }}
}

--[[ Local Functions ]]
local function exitApp2()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication", {
    appID = common.getHMIAppId(2),
    reason = "USER_EXIT" })
  common.getMobileSession(2):ExpectNotification("OnHMIStatus", { hmiLevel = "NONE" })
    :Do(function(_, d)
      common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
        eventName = "AUDIO_SOURCE",
        isActive = true })
    end)
  common.getMobileSession(1):ExpectNotification("OnHMIStatus")
  :Times(0)
  common.wait(5000)
end

local function appStartAudioStreaming(pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):StartService(10)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession(pAppId):StartStreaming(10,"files/MP3_1140kb.mp3")
          common.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = true })
        end)
    end)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function appStopStreaming(pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):StopStreaming("files/MP3_1140kb.mp3")
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
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
  runner.Step("App 2 starts Audio streaming", appStartAudioStreaming, { 2 })
  runner.Step("Exit App 2", exitApp2)
  runner.Step("App 2 stops streaming", appStopStreaming, { 2 })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
