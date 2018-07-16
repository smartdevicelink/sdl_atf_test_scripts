---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/1915
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = {
  [1] = "MEDIA",
  [2] = "NAVIGATION"
}
local isMixingAudioSupported = true

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType[1] }
config.application2.registerAppInterfaceParams.appHMIType = { appHMIType[2] }

--[[ Local Functions ]]
local function getHMIParams(pIsMixingSupported)
  local hmiParams = hmi_values.getDefaultHMITable()
  hmiParams.BasicCommunication.MixingAudioSupported.params.attenuatedSupported = pIsMixingSupported
  return hmiParams
end

local function activateApp1(pAppId, pTC, pAudioSS, pAppName)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(requestId)
    common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", {
    hmiLevel = "FULL",
    audioStreamingState = "AUDIBLE"
    })
    common.getMobileSession(2):ExpectNotification("OnHMIStatus", {
    hmiLevel = "LIMITED",
    audioStreamingState = "AUDIBLE"
    })
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, pAppName, pAudioSS, data.payload.audioStreamingState)
    end)
end

local function activateApp2(pAppId, pTC, pAudioSS, pAppName)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(requestId)
    common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", {
    hmiLevel = "FULL",
    audioStreamingState = "AUDIBLE"
    })
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, pAppName, pAudioSS, data.payload.audioStreamingState)
    end)
end

local function appStartAudioStreaming(pApp1Id, pApp2Id)
  common.getMobileSession(pApp2Id):StartService(10)
  :Do(function()
      common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
      :Do(function(_, data)
          common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
          common.getMobileSession(pApp2Id):StartStreaming(10,"files/MP3_1140kb.mp3")
          common.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = true })
        end)
    end)
  common.getMobileSession(pApp1Id):ExpectNotification("OnHMIStatus", {
  	hmiLevel = "FULL",
  	audioStreamingState = "ATTENUATED"
  	})
  :Times(1)
end

local function appStopStreaming(pApp1Id, pApp2Id)
  common.getMobileSession(pApp2Id):StopStreaming("files/MP3_1140kb.mp3")
  common.getMobileSession(pApp1Id):ExpectNotification("OnHMIStatus", {
    hmiLevel = "FULL",
    audioStreamingState = "AUDIBLE"
    })
  :Times(1)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session, isMixingSupported:" .. tostring(isMixingAudioSupported),
    common.start, { getHMIParams(isMixingAudioSupported) })

runner.Step("Set App1 Config", common.setAppConfig, { 2, appHMIType[2], false })
runner.Step("Register ".. appHMIType[2] .. " App", common.registerApp, { 2 })
runner.Step("Activate App2, audioState:" .. "AUDIBLE", activateApp2, { 2, 002, "AUDIBLE", "App2" })

runner.Step("Set App2 Config", common.setAppConfig, { 1, appHMIType[1], true })
runner.Step("Register " .. appHMIType[1] .." App", common.registerApp, { 1 })
runner.Step("Activate App1, audioState:" .. "AUDIBLE", activateApp1, { 1, 001, "AUDIBLE", "App1" })

runner.Step("App starts Audio streaming", appStartAudioStreaming, {1, 2})

runner.Step("App stops streaming", appStopStreaming, {1, 2})

runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)

