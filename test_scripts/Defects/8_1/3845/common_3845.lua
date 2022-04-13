---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local SDL = require('SDL')

--[[ Module ]]
local m = {}

--[[ Proxy Functions ]]
m.start = actions.start
m.preconditions = actions.preconditions
m.postconditions = actions.postconditions
m.getMobileSession = actions.getMobileSession
m.getHMIConnection = actions.getHMIConnection
m.registerApp = actions.registerApp
m.activateApp = actions.activateApp
m.runAfter = actions.run.runAfter
m.getHMIAppId = actions.app.getHMIId
m.SDLStoragePath = SDL.AppStorage.path

--[[ Common Variables ]]
m.tcs = {
  [01] = "UNSUPPORTED_RESOURCE",
  [02] = "WARNINGS",
  [03] = "RETRY",
  [04] = "SAVED",
  [05] = "WRONG_LANGUAGE",
  [06] = "TRUNCATED_DATA"
}

m.responsesStructures = {
  result = function(data, code) m.getHMIConnection():SendResponse(data.id, data.method, code, {}) end,
  error = function(data, code) m.getHMIConnection():SendError(data.id, data.method, code, "Error message") end
}

--[[ Local Variables ]]
local requestParams = {
  initialPrompt = {
    {
      text = "Makeyourchoice",
      type = "TEXT",
    },
  },
  audioPassThruDisplayText1 = "DisplayText1",
  samplingRate = "8KHZ",
  maxDuration = 2000,
  bitsPerSample = "8_BIT",
  audioType = "PCM"
}

local requestUIparams = {
  audioPassThruDisplayTexts = {
    { fieldName = "audioPassThruDisplayText1", fieldText = requestParams.audioPassThruDisplayText1 }
  },
  maxDuration = requestParams.maxDuration,
  muteAudio = requestParams.muteAudio
}

local requestTTSparams = {
  ttsChunks = requestParams.initialPrompt,
  speakType = "AUDIO_PASS_THRU"
}

local allParams = {
  requestParams = requestParams,
  requestUIparams = requestUIparams,
  requestTTSparams = requestTTSparams
}

--[[ Common Functions ]]
local function sendOnSystemContext(pCtx)
  m.getHMIConnection():SendNotification("UI.OnSystemContext", { appID = m.getHMIAppId(), systemContext = pCtx })
end

function m.performAudioPassThru(pResult)
  local cid = m.getMobileSession():SendRPC("PerformAudioPassThru", allParams.requestParams)
  allParams.requestUIparams.appID = m.getHMIAppId()
  m.getHMIConnection():ExpectRequest("TTS.Speak", allParams.requestTTSparams)
  :Do(function(_, data)
      m.getHMIConnection():SendNotification("TTS.Started")
      local function ttsSpeakResponse()
        pResult.speak.structure(data, pResult.speak.code)
        m.getHMIConnection():SendNotification("TTS.Stopped")
      end
      m.runAfter(ttsSpeakResponse, 100)
    end)
  m.getHMIConnection():ExpectRequest("UI.PerformAudioPassThru", allParams.requestUIparams)
  :Do(function(_, data)
      sendOnSystemContext("HMI_OBSCURED", allParams.requestUIparams.appID)
      local function uiResponse()
        pResult.performAudioPassThru.structure(data, pResult.performAudioPassThru.code)
        sendOnSystemContext("MAIN", allParams.requestUIparams.appID)
      end
      m.runAfter(uiResponse, 1500)
    end)
  m.getHMIConnection():ExpectNotification("UI.OnRecordStart", { appID = m.getHMIAppId() })
  m.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED" }, -- after PerformAudioPassThruResponse before OnSysCtx(MAIN)
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(4)
  m.getMobileSession():ExpectNotification("OnAudioPassThru")
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = pResult.general })
  :ValidIf(function()
      if utils.isFileExist(m.SDLStoragePath("audio.wav")) ~= true then
        return false, "Can not found file: audio.wav"
      end
      return true
    end)
end

return m
