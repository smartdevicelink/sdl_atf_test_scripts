-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1913
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) Non-media app is registered.
-- Description:
-- SDL must set NOT_AUDIBLE to non-media app in case this app is activated during phone call
-- Steps to reproduce:
-- 1) SDL receives SDL.ActivateApp(<appID_of_non-media_app>) request from HMI during phone call (non-media -> app that does NOT use audio channel).
-- Expected result:
-- SDL must respond SDL.ActivateApp (SUCCESS) to HMI send OnHMIStatus ("HMILevel: FULL, audioStreamingState: NOT_AUDIBLE") to requested for activation app.
-- Actual result:
-- SDL does not set required HMILevel and audioStreamingState.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function activateAppDuringPhoneCall(self)
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "PHONE_CALL", isActive = true })
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  EXPECT_HMIRESPONSE(requestId)
  self.mobileSession1:ExpectNotification("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_n)

runner.Title("Test")
runner.Step("Activate App during a phone call", activateAppDuringPhoneCall)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
