---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2227### Bug Report
--
-- Description:
-- Media Projection app is set to BACKGROUND instead of LIMITED in case AUDIO_SOURCE is active
-- 
-- Reproduction Steps:
-- 1) Projection Media app (HMItype=PROJECTION, isMedia=true) is registered
-- 2) App is activated (FULL, AUDIBLE, STREAMABLE)
-- 3) Activate Radio - OnEventChanged(AUDIO_SOURCE, true)
-- 
-- Expected Behavior:
-- Projection Media app is set to (LIMITED, NOT_AUDIBLE, STREAMABLE)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "PROJECTION" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Local Functions ]]
local function activateEmbeddedAudio()
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", videoStreamingState = "STREAMABLE" },
    { hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", videoStreamingState = "STREAMABLE" })
  :Times(2)
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId() })
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "AUDIO_SOURCE", isActive = true })
  utils.wait(2000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Activate Embedded Audio", activateEmbeddedAudio)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
