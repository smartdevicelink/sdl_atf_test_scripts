-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1906
--
-- Description:
-- Navigation app must be activated during active embedded navigation and "MixingAudioSupported" = true.
--
-- Precondition:
-- 1) MixingAudioSupported" = true at .ini file
-- 2) SDL and HMI are started.
-- 3) Navigation app is registered.
-- 4) Navigation app in LIMITED and AUDIBLE due to active embedded audio source
--
-- Steps to reproduce:
-- 1) SDL receives SDL.ActivateApp (<appID_of_navigation_app>) from HMI
-- SDL does:
-- a. send OnHMIStatus (FULL, AUDIBLE) to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local hmi_values = require('user_modules/hmi_values')

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

local function onEventChange()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "AUDIO_SOURCE", isActive = true })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set MixingAudioSupported=true in ini file", common.setSDLIniParameter, { "MixingAudioSupported", "true" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getHMIValues() })
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("onEventChange AUDIO_SOURCE true", onEventChange)
runner.Step("Activate App", common.activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
