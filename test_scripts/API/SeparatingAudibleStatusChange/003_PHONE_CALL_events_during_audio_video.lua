---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0264-Separating-the-change-of-Audible-status-and-the-change-of-HMI-Status.md
---------------------------------------------------------------------------------------------------
-- Description:
-- Check the processing of separating the change of Audible status and the change of HMI Status on 'PHONE_CALL' events
-- during audio/video streaming
-- In case:
-- 1) There is a mobile app which is audio/video source
-- 2) App starts Audio/Video streaming
-- 3) Mobile App is moving to another state by 'PHONE_CALL' event (isActive = true) from HMI
-- SDL does:
--  - send OnHMIStatus notification with 'audioStreamingState'= "NOT_AUDIBLE" parameter
--  - send Navigation.OnAudioDataStreaming(available=false)
--  - not send Navi.OnVideoDataStreaming(false) notification to HMI
-- In case:
-- 4) Mobile App is moving to another state by 'PHONE_CALL' event (isActive = false) from HMI
-- SDL does:
--  - send OnHMIStatus notification with 'audioStreamingState'= "AUDIBLE" parameter
--  - send Navigation.OnAudioDataStreaming(available=true)
--  - not send Navi.OnVideoDataStreaming(false) notification to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/SeparatingAudibleStatusChange/common')

--[[ Local Variables ]]
local appId = 1
local preAudioStreamState

local testCases = {
  [001] = { t = "PROJECTION", m = true, s = {
    [1] = { e = common.events.phoneCallStart,   l = "FULL",         a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = common.events.phoneCallEnd,     l = "FULL",         a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = common.events.deactivateApp,    l = "LIMITED",      a = "AUDIBLE",     v = "STREAMABLE" },
    [4] = { e = common.events.phoneCallStart,   l = "LIMITED",      a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [5] = { e = common.events.phoneCallEnd,     l = "LIMITED",      a = "AUDIBLE",     v = "STREAMABLE" }
    }
  },
  [002] = { t = "NAVIGATION", m = true, s = {
    [1] = { e = common.events.phoneCallStart,   l = "FULL",         a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [2] = { e = common.events.phoneCallEnd,     l = "FULL",         a = "AUDIBLE",     v = "STREAMABLE" },
    [3] = { e = common.events.deactivateApp,    l = "LIMITED",      a = "AUDIBLE",     v = "STREAMABLE" },
    [4] = { e = common.events.phoneCallStart,   l = "LIMITED",      a = "NOT_AUDIBLE", v = "STREAMABLE" },
    [5] = { e = common.events.phoneCallEnd,     l = "LIMITED",      a = "AUDIBLE",     v = "STREAMABLE" }
    }
  }
}

--[[ Local Functions ]]
local function appStartAudioStreaming()
  common.getMobileSession():StartService(10)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession():StartStreaming(10,"files/MP3_1140kb.mp3")
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
          common.getMobileSession():StartStreaming(11, "files/MP3_4555kb.mp3")
          common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
        end)
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function appStopStreaming()
  common.getMobileSession():StopStreaming("files/MP3_1140kb.mp3")
  common.getMobileSession():StopStreaming("files/MP3_4555kb.mp3")
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function doAction(pTC, pStep)
  common.checkHMIStatus(pTC, pStep.e.name, nil, pStep)
  local numOfOccurrOnAudioDataStreaming = (pStep.a == preAudioStreamState) and 0 or 1
  preAudioStreamState = pStep.a
  local isAvailable = true
  if pStep.a == "NOT_AUDIBLE" then isAvailable = false end
  common.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = isAvailable })
  :Times(numOfOccurrOnAudioDataStreaming)
  common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming")
  :Times(0)
  common.getHMIConnection():ExpectRequest("Navigation.StopAudioStream")
  :Times(0)
  common.getHMIConnection():ExpectRequest("Navigation.StopStream")
  :Times(0)
  pStep.e.func()
end

local function postconditions()
  common.postconditions()
  preAudioStreamState = nil
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  common.Title("TC[" .. string.format("%03d", n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. "]")
  common.Step("Clean environment", common.preconditions)
  common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  common.Step("Set App Config", common.setAppConfig, { appId, tc.t, tc.m })
  common.Step("Register App", common.registerApp, { appId })
  common.Step("Activate App", common.activateApp, { appId })
  common.Step("App starts Audio streaming", appStartAudioStreaming)
  common.Step("App starts Video streaming", appStartVideoStreaming)

  for i = 1, #tc.s do
    common.Step("Action:" .. tc.s[i].e.name .. ",hmiLevel:" .. tostring(tc.s[i].l), doAction, { n, tc.s[i] })
  end

  common.Step("Stop A/V streaming", appStopStreaming)
  common.Step("Clean sessions", common.cleanSessions)
  common.Step("Stop SDL", postconditions)
end
