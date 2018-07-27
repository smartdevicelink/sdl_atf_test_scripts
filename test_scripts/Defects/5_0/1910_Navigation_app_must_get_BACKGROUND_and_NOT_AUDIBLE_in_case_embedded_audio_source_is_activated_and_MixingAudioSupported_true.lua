-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1910
-- Precondition:
-- 1) "MixingAudioSupported" = true at .ini file.
-- 2) SDL and HMI are started.
-- 3) Navigation app is registered.
-- Description:
-- Navigation app must get BACKGROUND and NOT_AUDIBLE in case embedded audio source is activated and "MixingAudioSupported" = true
-- Steps to reproduce:
-- 1) Navigation app in FULL or LIMITED and AUDIBLE and SDL receives OnEventChanged (AUDIO_SOURCE, isActive=true) from HMI.
-- Expected result:
-- SDL must send OnHMIStatus (BACKGROUND, NOT_AUDIBLE) to mobile app.
-- Actual result:
-- SDL does not set required HMILevel and audioStreamingState.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local hmi_values = require('user_modules/hmi_values')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
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

local function activateNaviApp(self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  EXPECT_HMIRESPONSE(requestId)
  self.mobileSession1:ExpectNotification("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" },
	{ hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
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
runner.Step("Start SDL, HMI, connect Mobile, start Session", start, { getHMIValues })
runner.Step("RAI", common.rai_n)

runner.Title("Test")
runner.Step("Navi_App in BACKGROUND and NOT_AUDIBLE in case embedded audio source", activateNaviApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
