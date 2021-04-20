-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1910
-- Precondition:
-- 1) "MixingAudioSupported" = true at .ini file.
-- 2) SDL and HMI are started.
-- 3) Navigation app is registered.
-- Description:
-- Navigation app must get BACKGROUND and NOT_AUDIBLE in case embedded audio source is activated and "MixingAudioSupported" = true
-- Steps to reproduce:
-- 1) Navigation app in FULL or LIMITED and AUDIBLE and SDL receives OnEventChanged (AUDIO_SOURCE, isActive=true) from HMI.
-- Expected result:
-- SDL must send OnHMIStatus (BACKGROUND, NOT_AUDIBLE) to mobile app.
-- Actual result:
-- SDL does not set required HMILevel and audioStreamingState.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local hmi_values = require('user_modules/hmi_values')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.BasicCommunication.MixingAudioSupported.attenuatedSupported = true
  return params
end

local function activateApp()
  local cid = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  common.getHMIConnection():ExpectResponse(cid)
  common.getMobileSession():ExpectNotification("OnHMIStatus", {
    hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"
  })
end

local function onEventChange()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "AUDIO_SOURCE", isActive = true })
    common.getMobileSession():ExpectNotification("OnHMIStatus", {
    hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set MixingAudioSupported=true in ini file", common.setSDLIniParameter, { "MixingAudioSupported", "true" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getHMIValues() })
runner.Step("RAI", common.registerApp)
runner.Step("Activate App FULL", activateApp)

runner.Title("Test")
runner.Step("OnEventChanged AUDIO_SOURCE true", onEventChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
