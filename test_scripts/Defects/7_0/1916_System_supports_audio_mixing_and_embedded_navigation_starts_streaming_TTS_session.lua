---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1916
--
-- Description:
-- Media app: system supports audio mixing and embedded navigation starts streaming (TTS session)
-- Precondition:
-- 1) "MixingAudioSupported" = true at .ini file.
-- 2) SDL and HMI are started.
-- 3) App is registered and activated
-- Steps to reproduce:
-- 1) Media app in LIMITED and AUDIBLE due to active embedded navigation
-- 2) HMI sends TTS.Started to the SDL(embedded navigation starts streaming)
-- 3)  HMI sends TTS.Stopped to the SDL(embedded navigation stop streaming)
-- SDL does:
-- send OnHMIStatus (LIMITED, ATTENUATED) to mobile app when embedded navigation starts streaming
-- send OnHMIStatus (LIMITED, AUDIBLE) to mobile app right after embedded navigation stops streaming(SDL receives TTS.Stopped from HMI)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Local Functions ]]
local function activateEmbeddedNavi()
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId() })
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "EMBEDDED_NAVI", isActive = true })
  utils.wait(1000)
end

local function ttsStarted()
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "ATTENUATED" })
  common.getHMIConnection():SendNotification("TTS.Started")
  utils.wait(1000)
end

local function ttsStopped()
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
  common.getHMIConnection():SendNotification("TTS.Stopped")
  utils.wait(1000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Media app during active embedded navigation", activateEmbeddedNavi)
runner.Step("TTS Started", ttsStarted)
runner.Step("TTS Stopped", ttsStopped)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
