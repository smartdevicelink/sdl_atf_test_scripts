---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/2322
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) Media app is registered and activated.
-- Description:
-- SDL must set media app to LIMITED and AUDIBLE due to active embedded navigation
-- Steps to reproduce:
-- 1) SDL and HMI are started.
-- 2) Media app is registered and activated(FULL, AUDIBLE)
-- 3) SDL receives OnEventChanged(EMBEDDED_NAVI, isActive=true) from HMI.
-- Expected result:
-- SDL must send OnHMIStatus(LIMITED, AUDIBLE) to mobile app.
-- Actual result:
-- SDL sends OnHMIStatus(BACKGROUND, NOT_AUDIBLE) to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true 

--[[ Local Functions ]]
local function activateApp()
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" },
	{ hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
	:Times(2)
  :Do(function(exp)
	if exp.occurences == 1 then
		common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", { eventName = "EMBEDDED_NAVI", isActive = true })
	end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)

runner.Title("Test")
runner.Step("Deactivation App from FULL to BACKGROUND due to active embedded navigation", activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
