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

local function activateApp(pAppId, pTC, pAudioSS, pAppName)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
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

local function appStopStreaming()
  common.getMobileSession(2):StopStreaming("files/MP3_1140kb.mp3")
  common.getMobileSession():ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  common.getMobileSession(2):ExpectNotification("OnHMIStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session, isMixingSupported:" .. tostring(isMixingAudioSupported),
    common.start, { getHMIParams(isMixingAudioSupported) })

runner.Step("Set App Config", common.setAppConfig, { 2, "NAVIGATION", true })
runner.Step("Register App", common.registerApp, { 2 })
runner.Step("Activate App2, audioState:" .. "AUDIBLE", activateApp, { 2, 001, "AUDIBLE", "App2" })

runner.Step("Set App Config", common.setAppConfig, { 1, "MEDIA", true })
runner.Step("Register " .. appHMIType[1] .. " App", common.registerApp, { 1 })
runner.Step("Activate App1, audioState:" .. "AUDIBLE", activateApp, { 1, 001, "AUDIBLE", "App1" })

runner.Step("App starts Audio streaming", appStartAudioStreaming, { 1, 2 })

runner.Step("App stops streaming", appStopStreaming)

runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL", common.postconditions)
