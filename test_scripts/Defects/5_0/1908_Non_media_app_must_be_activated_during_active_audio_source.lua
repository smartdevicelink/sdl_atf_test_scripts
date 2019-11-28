-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1908
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) Non-media app is registered.
-- 3) Non-media app in BACKGROUND and NOT_AUDIBLE due to active embedded audio source
-- Description:
-- Non-media app must be activated during active audio source
-- Steps to reproduce:
-- 1) SDL receives SDL.ActivateApp(<appID_of_non-media_app>) from HMI
-- Expected result:
-- SDL must respond SDL.ActivateApp (SUCCESS) to HMI send OnHMIStatus (FULL, NOT_AUDIBLE).
-- Actual result:
-- SDL does not set required HMILevel and audioStreamingState.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function activateApp()
  local cid = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  common.getHMIConnection():ExpectResponse(cid)
  common.getMobileSession():ExpectNotification("OnHMIStatus", {
    hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
  })
end

local function deactivateApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnHMIStatus", {
    hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", videoStreamingState = "NOT_STREAMABLE"
  })
end

local function onEventChange()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "AUDIO_SOURCE", isActive = true
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App FULL", activateApp)
runner.Step("Deactivate App BACKGROUND", deactivateApp)

runner.Title("Test")
runner.Step("AUDIO sourse is activated", onEventChange)
runner.Step("Activate App FULL", activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
