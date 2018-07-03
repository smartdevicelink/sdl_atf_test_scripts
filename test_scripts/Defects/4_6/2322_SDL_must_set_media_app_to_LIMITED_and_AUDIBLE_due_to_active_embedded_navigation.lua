---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/2322
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) Media app is registered and activated.
-- Description:
-- SDL must set media app to LIMITED and NOT_AUDIBLE due to active embedded navigation
-- Steps to reproduce:
-- 1) Media app in FULL and AUDIBLE and SDL receives OnEventChanged (EMBEDDED_NAVI, isActive=true) from HMI.
-- Expected result:
-- SSDL must send OnHMIStatus (LIMITED, NOT_AUDIBLE) to mobile app.
-- Actual result:
-- SDL sends OnHMIStatus (BACKGROUND, NOT_AUDIBLE) to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local mobile_session = require('mobile_session')

--[[ Local Variables ]]
config.application1 = {
	registerAppInterfaceParams = {
		syncMsgVersion =
		{
			majorVersion = 3,
			minorVersion = 0
		},
		appName = "Test Application",
		isMediaApplication = true,
		languageDesired = 'EN-US',
		hmiDisplayLanguageDesired = 'EN-US',
		appHMIType = { "MEDIA" },
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

local function activate_app(self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID })
  EXPECT_HMIRESPONSE(requestId)
  EXPECT_NOTIFICATION("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" },
	{ hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
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
runner.Step("RAI", rai_n)

runner.Title("Test")
runner.Step("Activate App", activate_app)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
