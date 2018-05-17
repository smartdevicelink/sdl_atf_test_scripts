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
  [010] = {
    [1] = { t = "NAVIGATION",    m = false, aSS = { "AUDIBLE", "AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "PROJECTION",    m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "STREAMABLE" } }
  },
  [011] = {
    [1] = { t = "NAVIGATION",    m = false, aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "NOT_STREAMABLE" } }
  },
  [012] = {
    [1] = { t = "NAVIGATION",    m = true,  aSS = { "AUDIBLE", "AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "PROJECTION",    m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "STREAMABLE" } }
  },
  [013] = {
    [1] = { t = "NAVIGATION",    m = true,  aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "NOT_STREAMABLE" } }
  },
  [014] = {
    [1] = { t = "COMMUNICATION", m = false, aSS = { "AUDIBLE", nil },       vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "PROJECTION",    m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "STREAMABLE" } }
  },
  [015] = {
    [1] = { t = "COMMUNICATION", m = false, aSS = { "AUDIBLE", nil },       vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "NOT_STREAMABLE" } }
  },
  [016] = {
    [1] = { t = "COMMUNICATION", m = true,  aSS = { "AUDIBLE", nil },       vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "PROJECTION",    m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "STREAMABLE" } }
  },
  [017] = {
    [1] = { t = "COMMUNICATION", m = true,  aSS = { "AUDIBLE", nil },       vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "NOT_STREAMABLE" } }
  },
  [018] = {
    [1] = { t = "PROJECTION",    m = true,  aSS = { "AUDIBLE", "AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "PROJECTION",    m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "STREAMABLE" } }
  },
  [019] = {
    [1] = { t = "PROJECTION",    m = true,  aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "NOT_STREAMABLE" } }
  },
  [020] = {
    [1] = { t = "MEDIA",         m = true,  aSS = { "AUDIBLE", nil },       vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "PROJECTION",    m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "STREAMABLE" } }
  },
  [021] = {
    [1] = { t = "MEDIA",         m = true,  aSS = { "AUDIBLE", nil },       vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "NOT_STREAMABLE" } }
  },
  [022] = {
    [1] = { t = "DEFAULT",       m = true,  aSS = { "AUDIBLE", nil },       vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "PROJECTION",    m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "STREAMABLE" } }
  },
  [023] = {
    [1] = { t = "DEFAULT",       m = true,  aSS = { "AUDIBLE", nil },       vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = false, aSS = { nil, "NOT_AUDIBLE" },   vSS = { nil, "NOT_STREAMABLE" } }
  },
  [024] = {
    [1] = { t = "NAVIGATION",    m = false, aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "NAVIGATION",    m = false, aSS = { nil, "AUDIBLE" },           vSS = { nil, "STREAMABLE" } }
  },
  [025] = {
    [1] = { t = "NAVIGATION",    m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "NAVIGATION",    m = false, aSS = { nil, "AUDIBLE" },           vSS = { nil, "STREAMABLE" } }
  },
  [026] = {
    [1] = { t = "NAVIGATION",    m = false, aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "NAVIGATION",    m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "STREAMABLE" } }
  },
  [027] = {
    [1] = { t = "NAVIGATION",    m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "NAVIGATION",    m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "STREAMABLE" } }
  },
  [028] = {
    [1] = { t = "COMMUNICATION", m = false, aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "NOT_STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "COMMUNICATION", m = false, aSS = { nil, "AUDIBLE" },           vSS = { nil, "NOT_STREAMABLE" } }
  },
  [029] = {
    [1] = { t = "COMMUNICATION", m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "NOT_STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "COMMUNICATION", m = false, aSS = { nil, "AUDIBLE" },           vSS = { nil, "NOT_STREAMABLE" } }
  },
  [030] = {
    [1] = { t = "COMMUNICATION", m = false, aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "NOT_STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "COMMUNICATION", m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "NOT_STREAMABLE" } }
  },
  [031] = {
    [1] = { t = "COMMUNICATION", m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "NOT_STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "COMMUNICATION", m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "NOT_STREAMABLE" } }
  },
  [032] = {
    [1] = { t = "NAVIGATION",    m = false, aSS = { "AUDIBLE", "AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "PROJECTION",    m = true,  aSS = { nil, "AUDIBLE" },       vSS = { nil, "STREAMABLE" } }
  },
  [033] = {
    [1] = { t = "NAVIGATION",    m = false, aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "MEDIA",         m = true,  aSS = { nil, "AUDIBLE" },       vSS = { nil, "NOT_STREAMABLE" } }
  },
  [034] = {
    [1] = { t = "NAVIGATION",    m = false, aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = true,  aSS = { nil, "AUDIBLE" },       vSS = { nil, "NOT_STREAMABLE" } }
  },
  [035] = {
    [1] = { t = "NAVIGATION",    m = false, aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "COMMUNICATION", m = true,  aSS = { nil, "AUDIBLE" },       vSS = { nil, "NOT_STREAMABLE" } }
  },
  [036] = {
    [1] = { t = "NAVIGATION",    m = true, aSS = { "AUDIBLE", "AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "PROJECTION",    m = true, aSS = { nil, "AUDIBLE" },       vSS = { nil, "STREAMABLE" } }
  },
  [037] = {
    [1] = { t = "NAVIGATION",    m = true, aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "MEDIA",         m = true, aSS = { nil, "AUDIBLE" },       vSS = { nil, "NOT_STREAMABLE" } }
  },
  [038] = {
    [1] = { t = "NAVIGATION",    m = true, aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = true, aSS = { nil, "AUDIBLE" },       vSS = { nil, "NOT_STREAMABLE" } }
  },
  [039] = {
    [1] = { t = "NAVIGATION",    m = true, aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "COMMUNICATION", m = true, aSS = { nil, "AUDIBLE" },       vSS = { nil, "NOT_STREAMABLE" } }
  },
  [040] = {
    [1] = { t = "COMMUNICATION", m = false, aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "PROJECTION",    m = true,  aSS = { nil, "AUDIBLE" }, vSS = { nil, "STREAMABLE" } }
  },
  [041] = {
    [1] = { t = "COMMUNICATION", m = false, aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "MEDIA",         m = true,  aSS = { nil, "AUDIBLE" }, vSS = { nil, "NOT_STREAMABLE" } }
  },
  [042] = {
    [1] = { t = "COMMUNICATION", m = false, aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = true,  aSS = { nil, "AUDIBLE" }, vSS = { nil, "NOT_STREAMABLE" } }
  },
  [043] = {
    [1] = { t = "COMMUNICATION", m = false, aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "NAVIGATION",    m = true,  aSS = { nil, "AUDIBLE" }, vSS = { nil, "STREAMABLE" } }
  },
  [044] = {
    [1] = { t = "COMMUNICATION", m = true, aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "PROJECTION",    m = true, aSS = { nil, "AUDIBLE" }, vSS = { nil, "STREAMABLE" } }
  },
  [045] = {
    [1] = { t = "COMMUNICATION", m = true, aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "MEDIA",         m = true, aSS = { nil, "AUDIBLE" }, vSS = { nil, "NOT_STREAMABLE" } }
  },
  [046] = {
    [1] = { t = "COMMUNICATION", m = true, aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "DEFAULT",       m = true, aSS = { nil, "AUDIBLE" }, vSS = { nil, "NOT_STREAMABLE" } }
  },
  [047] = {
    [1] = { t = "COMMUNICATION", m = true, aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "NAVIGATION",    m = true, aSS = { nil, "AUDIBLE" }, vSS = { nil, "STREAMABLE" } }
  },
  [048] = {
    [1] = { t = "PROJECTION",    m = true,  aSS = { "AUDIBLE", "AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "NAVIGATION",    m = false, aSS = { nil, "AUDIBLE" },       vSS = { nil, "STREAMABLE" } }
  },
  [049] = {
    [1] = { t = "PROJECTION",    m = true,  aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "COMMUNICATION", m = false, aSS = { nil, "AUDIBLE" },       vSS = { nil, "NOT_STREAMABLE" } }
  },
  [050] = {
    [1] = { t = "PROJECTION",    m = true,  aSS = { "AUDIBLE", "AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "NAVIGATION",    m = true,  aSS = { nil, "AUDIBLE" },       vSS = { nil, "STREAMABLE" } }
  },
  [051] = {
    [1] = { t = "PROJECTION",    m = true,  aSS = { "AUDIBLE", nil },       vSS = { "STREAMABLE", nil } },
    [2] = { t = "COMMUNICATION", m = true,  aSS = { nil, "AUDIBLE" },       vSS = { nil, "NOT_STREAMABLE" } }
  },
  [052] = {
    [1] = { t = "MEDIA",         m = true,  aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "NAVIGATION",    m = false, aSS = { nil, "AUDIBLE" }, vSS = { nil, "STREAMABLE" } }
  },
  [053] = {
    [1] = { t = "MEDIA",         m = true,  aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "COMMUNICATION", m = false, aSS = { nil, "AUDIBLE" }, vSS = { nil, "NOT_STREAMABLE" } }
  },
  [054] = {
    [1] = { t = "MEDIA",         m = true,  aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "NAVIGATION",    m = true,  aSS = { nil, "AUDIBLE" }, vSS = { nil, "STREAMABLE" } }
  },
  [055] = {
    [1] = { t = "MEDIA",         m = true,  aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "COMMUNICATION", m = true,  aSS = { nil, "AUDIBLE" }, vSS = { nil, "NOT_STREAMABLE" } }
  },
  [056] = {
    [1] = { t = "DEFAULT",       m = true,  aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "NAVIGATION",    m = false, aSS = { nil, "AUDIBLE" }, vSS = { nil, "STREAMABLE" } }
  },
  [057] = {
    [1] = { t = "DEFAULT",       m = true,  aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "COMMUNICATION", m = false, aSS = { nil, "AUDIBLE" }, vSS = { nil, "NOT_STREAMABLE" } }
  },
  [058] = {
    [1] = { t = "DEFAULT",       m = true,  aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "NAVIGATION",    m = true,  aSS = { nil, "AUDIBLE" }, vSS = { nil, "STREAMABLE" } }
  },
  [059] = {
    [1] = { t = "DEFAULT",       m = true,  aSS = { "AUDIBLE", nil }, vSS = { "NOT_STREAMABLE", nil } },
    [2] = { t = "COMMUNICATION", m = true,  aSS = { nil, "AUDIBLE" }, vSS = { nil, "NOT_STREAMABLE" } }
  },
  [060] = {
    [1] = { t = "PROJECTION", m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "PROJECTION", m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "STREAMABLE" } }
  },
  [061] = {
    [1] = { t = "PROJECTION", m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "STREAMABLE", "STREAMABLE" } },
    [2] = { t = "MEDIA",      m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "NOT_STREAMABLE" } }
  },
  [062] = {
    [1] = { t = "PROJECTION", m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "STREAMABLE", "STREAMABLE" } },
    [2] = { t = "DEFAULT",    m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "NOT_STREAMABLE" } }
  },
  [063] = {
    [1] = { t = "MEDIA",      m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "NOT_STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "PROJECTION", m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "STREAMABLE" } }
  },
  [064] = {
    [1] = { t = "MEDIA",      m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "NOT_STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "MEDIA",      m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "NOT_STREAMABLE" } }
  },
  [065] = {
    [1] = { t = "MEDIA",      m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "NOT_STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "DEFAULT",    m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "NOT_STREAMABLE" } }
  },
  [066] = {
    [1] = { t = "DEFAULT",    m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "NOT_STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "PROJECTION", m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "STREAMABLE" } }
  },
  [067] = {
    [1] = { t = "DEFAULT",    m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "NOT_STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "MEDIA",      m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "NOT_STREAMABLE" } }
  },
  [068] = {
    [1] = { t = "DEFAULT",    m = true,  aSS = { "AUDIBLE", "NOT_AUDIBLE" }, vSS = { "NOT_STREAMABLE", "NOT_STREAMABLE" } },
    [2] = { t = "DEFAULT",    m = true,  aSS = { nil, "AUDIBLE" },           vSS = { nil, "NOT_STREAMABLE" } }
  },
}

--[[ Local Functions ]]
local function activateApp2(pTC, pAudioSSApp1, pVideoSSApp1, pAudioSSApp2, pVideoSSApp2)
  local count = 1
  if pAudioSSApp1 == nil and pVideoSSApp1 == nil then count = 0 end
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(2) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(1):ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, "App1", pAudioSSApp1, data.payload.audioStreamingState)
    end)
  :ValidIf(function(_, data)
      return common.checkVideoSS(pTC, "App1", pVideoSSApp1, data.payload.videoStreamingState)
    end)
  :Times(count)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, "App2", pAudioSSApp2, data.payload.audioStreamingState)
    end)
  :ValidIf(function(_, data)
      return common.checkVideoSS(pTC, "App2", pVideoSSApp2, data.payload.videoStreamingState)
    end)
end

local function deactivateApp1(pTC, pAudioSSApp1, pVideoSSApp1)
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
  common.getMobileSession(1):ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, "App1", pAudioSSApp1, data.payload.audioStreamingState)
    end)
  :ValidIf(function(_, data)
      return common.checkVideoSS(pTC, "App1", pVideoSSApp1, data.payload.videoStreamingState)
    end)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function getMsg(pTC, pAppId, pNotifId)
  if pTC[pAppId].aSS[pNotifId] == nil and pTC[pAppId].vSS[pNotifId] == nil then
    return "NO"
  else
    return pTC[pAppId].aSS[pNotifId] .. ":" .. pTC[pAppId].vSS[pNotifId]
  end
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
  runner.Step("Deact. App 1:" .. "App1:" .. getMsg(tc, 1, 1) .. " App2:" .. getMsg(tc, 2, 1),
    deactivateApp1, { n, tc[1].aSS[1], tc[1].vSS[1] })
  runner.Step("Act. App 2:" .. "App1:" .. getMsg(tc, 1, 2) .. " App2:" .. getMsg(tc, 2, 2),
    activateApp2, { n, tc[1].aSS[2], tc[1].vSS[2], tc[2].aSS[2], tc[2].vSS[2] })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
