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
local mobile_session = require('mobile_session')

--[[ Local Variables ]]
config.application1 = {
	registerAppInterfaceParams = {
		syncMsgVersion = {
			majorVersion = 3,
			minorVersion = 0
		},
		appName = "Test Application",
		isMediaApplication = false,
		languageDesired = 'EN-US',
		hmiDisplayLanguageDesired = 'EN-US',
		appHMIType = { "DEFAULT" },
		appID = "123456",
		deviceInfo = {
			os = "Android",
			carrier = "Megafon",
			firmwareRev = "Name: Linux, Version: 3.4.0-perf",
			osVersion = "4.4.2",
			maxNumberRFCOMMPorts = 1
		}
	}
}

local default_app_params = config.application1.registerAppInterfaceParams

--[[ Local Functions ]]
local function rai_n(self)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = self.mobileSession:StartRPC()
  on_rpc_service_started:Do(function()
    local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", default_app_params)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function(_,data)
        self.HMIAppID = data.params.application.appID
	end)
    EXPECT_RESPONSE(correlation_id, {success = true, resultCode = "SUCCESS"})
    :Do(function()
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
    EXPECT_NOTIFICATION("OnPermissionsChange")
  end)
end

local function activateAppDuringPhoneCall(self)
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "PHONE_CALL", isActive = true })
	self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID })
  EXPECT_HMIRESPONSE(requestId)
  EXPECT_NOTIFICATION("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", rai_n)

runner.Title("Test")
runner.Step("Activate App during a phone call", activateAppDuringPhoneCall)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
