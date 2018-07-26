-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1910
-- Precondition:
-- 1) "MixingAudioSupported" = true at .ini file.
-- 2) SDL and HMI are started.
-- 3) Media app is registered.
-- Description:
-- Navigation app must get LIMITED and AUDIBLE in case embedded audio source is activated and "MixingAudioSupported" = true
-- Steps to reproduce:
-- 1) Navigation app in FULL or LIMITED and AUDIBLE and SDL receives OnEventChanged (AUDIO_SOURCE, isActive=true) from HMI.
-- Expected result:
-- SDL must send OnHMIStatus (LIMITED, NOT_AUDIBLE) to mobile app.
-- Actual result:
-- SDL does not set required HMILevel and audioStreamingState.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local mobile_session = require('mobile_session')
local hmi_values = require('user_modules/hmi_values')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Local Variables ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.BasicCommunication.MixingAudioSupported.attenuatedSupported = true
  return params
end

local function start(getHMIParams, self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
      self:initHMI(self)
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMI_onReady(getHMIParams)
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
              self:connectMobile()
              :Do(function()
                  commonFunctions:userPrint(35, "Mobile connected")
                  common.allow_sdl(self)
                end)
            end)
        end)
    end)
end

config.application1 = {
	registerAppInterfaceParams = {
		syncMsgVersion = { majorVersion = 3, minorVersion = 0 },
		appName = "Test Application",
		isMediaApplication = false,
		languageDesired = 'EN-US',
		hmiDisplayLanguageDesired = 'EN-US',
		appHMIType = { "NAVIGATION" },
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

local function activateNaviApp(self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID })
  EXPECT_HMIRESPONSE(requestId)
  EXPECT_NOTIFICATION("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" },
	{ hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
	:Times(2)
  :Do(function(exp)
	if exp.occurences == 1 then
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "AUDIO_SOURCE", isActive = true})
	end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start, { getHMIValues() })
runner.Step("RAI", rai_n)

runner.Title("Test")
runner.Step("Activate NaviApp", activateNaviApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
