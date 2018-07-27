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
local common = require('test_scripts/Defects/commonDefects')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function nonMediaActivateApp(self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  EXPECT_HMIRESPONSE(requestId)
  self.mobileSession1:ExpectNotification("OnHMIStatus",
  { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

local function onEventChange(self)
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "AUDIO_SOURCE", isActive = true})
  self.mobileSession1:ExpectNotification("OnHMIStatus",
  { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
  { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  :Times(2)
  :Do(function(exp)
    if exp.occurences == 1 then
      local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
      EXPECT_HMIRESPONSE(requestId)
      self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "AUDIO_SOURCE", isActive = false})
    end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_n)
runner.Step("Non-media app activated", nonMediaActivateApp)

runner.Title("Test")
runner.Step("Non_media app in BACKGROUND and NOT_AUDIBLE due to active embedded audio source", onEventChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
