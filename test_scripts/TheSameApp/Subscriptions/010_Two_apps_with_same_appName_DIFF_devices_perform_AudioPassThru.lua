---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- Two mobile applications with the same appNames and different appIds from different mobiles send
-- PerformAudioPassThru requests and receive OnVehicleData notifications.
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobiles №1 and №2 are connected to SDL
-- 3) App 1 registered on Mobile №1
-- 4) App 2 registered on Mobile №2 with the same appName as App 1
-- 5) Activate App 1 and App 2
--
-- Steps:
-- 1) Mobile №1 App 1 requested PerformAudioPassThru
--   Check:
--    SDL sends TTS.Speak to HMI
--    SDL sends UI.PerformAudioPassThru with hmiAppId that represents App1 to HMI
-- 2) HMI sent UI.OnSystemContext(systemContext = "HMI_OBSCURED") notification with hmiAppId that represents App 1
--   Check:
--    SDL sends OnHMIStatus(systemContext = "HMI_OBSCURED") notification to Mobile №1
--    SDL sends OnAudioPassThru notification with binary data to Mobile №1
--    SDL does NOT send OnHMIStatus notification to Mobile №2
--    SDL does NOT send OnAudioPassThru notification to Mobile №2
-- 3) HMI sent UI.OnSystemContext(systemContext = "MAIN") notification with hmiAppId that represents App 1
--    HMI sent UI.PerformAudioPassThru ("SUCCESS") response
--   Check:
--    SDL sends OnHMIStatus(systemContext = "HMI_OBSCURED") notification to Mobile №1
--    SDL sends PerformAudioPassThru("SUCCESS") response to Mobile №1
--    SDL does NOT send OnHMIStatus notification to Mobile №2
--    SDL does NOT send PerformAudioPassThru response to Mobile №2
-- 4) Mobile №2 App 2 requested PerformAudioPassThru
--   Check:
--    SDL sends TTS.Speak to HMI
--    SDL sends UI.PerformAudioPassThru with hmiAppId that represents App 2 to HMI
-- 5) HMI sent UI.OnSystemContext(systemContext = "HMI_OBSCURED") notification with hmiAppId that represents App 2
--   Check:
--    SDL sends OnHMIStatus(systemContext = "HMI_OBSCURED") notification to Mobile №2
--    SDL sends OnAudioPassThru notification with binary data to Mobile №2
--    SDL does NOT send OnHMIStatus notification to Mobile №1
--    SDL does NOT send OnAudioPassThru notification to Mobile №1
-- 6) HMI sent UI.OnSystemContext(systemContext = "MAIN") notification with hmiAppId that represents App 2
--    HMI sent UI.PerformAudioPassThru ("SUCCESS") response
--   Check:
--    SDL sends OnHMIStatus(systemContext = "HMI_OBSCURED") notification to Mobile №2
--    SDL sends PerformAudioPassThru("SUCCESS") response to Mobile №2
--    SDL does NOT send OnHMIStatus notification to Mobile №1
--    SDL does NOT send PerformAudioPassThru response to Mobile №1
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = { appName = "Test Application", appID = "0001",  fullAppID = "0000001" },
  [2] = { appName = "Test Application", appID = "00022", fullAppID = "00000022" }
}

local audioGroup = {
  rpcs = {
    PerformAudioPassThru   = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"} },
    OnAudioPassThru        = { hmi_levels = {"BACKGROUND", "FULL", "LIMITED"} },
  }
}

local requestParams = {
  initialPrompt = { { text = "Makeyourchoice", type = "TEXT" } },
  audioPassThruDisplayText1 = "DisplayText1",
  audioPassThruDisplayText2 = "DisplayText2",
  samplingRate = "8KHZ",
  maxDuration = 2000,
  bitsPerSample = "8_BIT",
  audioType = "PCM",
  muteAudio = true
}

local allParams = {
  requestParams = requestParams,
  requestUiParams = {
    audioPassThruDisplayTexts = {
      {
        fieldName = "audioPassThruDisplayText1",
        fieldText = requestParams.audioPassThruDisplayText1
      },
      {
        fieldName = "audioPassThruDisplayText2",
        fieldText = requestParams.audioPassThruDisplayText2
      }
    },
    maxDuration = requestParams.maxDuration,
    muteAudio = requestParams.muteAudio
  },
  requestTtsParams = {
    ttsChunks = common.cloneTable(requestParams.initialPrompt),
    speakType = "AUDIO_PASS_THRU"
  }
}

--[[ Local Functions ]]
local function modifyAudioGroupInPT(pt)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null

  pt.policy_table.functional_groupings["Audio-1"] = audioGroup
  pt.policy_table.app_policies[appParams[1].fullAppID] = common.cloneTable(pt.policy_table.app_policies["default"])
  pt.policy_table.app_policies[appParams[1].fullAppID].groups = {"Base-4", "Audio-1"}
  pt.policy_table.app_policies[appParams[2].fullAppID] = common.cloneTable(pt.policy_table.app_policies["default"])
  pt.policy_table.app_policies[appParams[2].fullAppID].groups = {"Base-4", "Audio-1"}
end

local function performAudioPassThru(pAppId, pParams)
  local params = common.cloneTable(pParams)
  local anotherAppId = pAppId == 1 and 2 or 1
  local mobSessionCurrent = common.mobile.getSession(pAppId)
  local mobSessionAnother = common.mobile.getSession(anotherAppId)
  local hmi = common.hmi.getConnection()
  local cid = mobSessionCurrent:SendRPC("PerformAudioPassThru", params.requestParams)
  params.requestUiParams.appID = common.app.getHMIId(pAppId)
  hmi:ExpectRequest("TTS.Speak", params.requestTtsParams)
  :Do(function(_,data)
    hmi:SendNotification("TTS.Started")
    local function ttsSpeakResponse()
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
      hmi:SendNotification("TTS.Stopped")
    end
    common.run.runAfter(ttsSpeakResponse, 50)
  end)
  hmi:ExpectRequest("UI.PerformAudioPassThru", params.requestUiParams)
  :Do(function(_,data)
    hmi:SendNotification("UI.OnSystemContext", {appID = params.requestUiParams.appID, systemContext = "HMI_OBSCURED"})
    local function uiResponse()
      hmi:SendResponse(data.id, data.method, "SUCCESS", {})
      hmi:SendNotification("UI.OnSystemContext", { appID = params.requestUiParams.appID, systemContext = "MAIN" })
    end
    common.run.runAfter(uiResponse, 1500)
  end)
  hmi:ExpectNotification("UI.OnRecordStart", { appID = params.requestUiParams.appID })
  mobSessionCurrent:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(3)
  mobSessionCurrent:ExpectNotification("OnAudioPassThru")
  mobSessionAnother:ExpectNotification("OnHMIStatus"):Times(0)
  mobSessionAnother:ExpectNotification("OnAudioPassThru"):Times(0)
  mobSessionCurrent:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, { modifyAudioGroupInPT })
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App 1 from device 1", common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Register App 2 from device 2", common.registerAppEx, { 2, appParams[2], 2 })
runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("Activate App 1", common.app.activate, { 1 })

runner.Title("Test")
runner.Step("App 1 from device 1 PerformAudioPassThru", performAudioPassThru, { 1, allParams })

runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App 2 from device 2 PerformAudioPassThru", performAudioPassThru, { 2, allParams })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
