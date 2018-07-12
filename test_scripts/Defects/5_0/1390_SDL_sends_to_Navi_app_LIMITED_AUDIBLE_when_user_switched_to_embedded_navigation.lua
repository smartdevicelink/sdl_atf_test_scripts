-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1390
--
-- Precondition:
-- 1) Core, HMI started.
-- 2) App is registered and activated (FULL HMI level).
-- Description:
--
-- Steps to reproduce:
-- 1) Switch to embedded navigation: BC.OnEventChanged (eventName = "EMBEDDED_NAVI", isActive = true).
-- Expected result:
-- SDL sends OnHMIStatus (BACKGROUND, NOT_AUDIBLE) to this media app.
-- Actual result:
-- SDL sends OnHMIStatus (LIMITED, NOT_AUDIBLE) to this media app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Local Functions ]]
local function OnEventChanged(self)
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "EMBEDDED_NAVI", isActive = true })
	self.mobileSession1:ExpectNotification("OnHMIStatus",
	{ hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_n)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("onEventChange EMBEDDED_NAVI true", OnEventChanged)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
