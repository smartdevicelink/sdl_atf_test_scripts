---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/2322
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) Media app is registered and activated.
-- Description:
-- SDL must set media app to LIMITED and NOT_AUDIBLE due to active embedded navigation
-- Steps to reproduce:
-- 1) SDL and HMI are started.
-- 2) Media app is registered and activated(FULL, AUDIBLE)
-- 3) SDL receives OnEventChanged(EMBEDDED_NAVI, isActive=true) from HMI.
-- Expected result:
-- SDL must send OnHMIStatus(LIMITED, NOT_AUDIBLE) to mobile app.
-- Actual result:
-- SDL sends OnHMIStatus(BACKGROUND, NOT_AUDIBLE) to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true 

--[[ Local Functions ]]
local function activate_app(self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  EXPECT_HMIRESPONSE(requestId)
  self.mobileSession1:ExpectNotification("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" },
	{ hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
	:Times(2)
  :Do(function(exp)
	if exp.occurences == 1 then
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "EMBEDDED_NAVI", isActive = true})
	end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_n)

runner.Title("Test")
runner.Step("Deactivation App from FULL to BACKGROUND due to active embedded navigation", activate_app)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
