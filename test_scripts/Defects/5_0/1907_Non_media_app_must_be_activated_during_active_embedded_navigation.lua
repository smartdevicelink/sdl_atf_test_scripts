-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1907
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) Non-media app is registered.
-- 3) Non-media app in BACKGROUND and NOT_AUDIBLE due to active embedded navigation
-- Description:
-- Non-media app must be activated during active embedded navigation
-- Steps to reproduce:
-- 1) SDL receives SDL.ActivateApp(<appID_of_non-media_app>) from HMI
-- Expected result:
-- SDL must respond SDL.ActivateApp (SUCCESS) to HMI send OnHMIStatus (FULL, NOT_AUDIBLE).
-- Actual result:
-- SDL does not set required HMILevel and audioStreamingState.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function activate_app()
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  EXPECT_HMIRESPONSE(requestId)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

local function deactivateApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
	{ hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" })
end

local function onEventChange()
	common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
	{eventName = "EMBEDDED_NAVI", isActive = true})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", activate_app)
runner.Step("Deactivate App BACKGROUND", deactivateApp)
runner.Step("onEventChange EMBEDDED_NAVI true", onEventChange)

runner.Title("Test")
runner.Step("Activate App", activate_app)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
