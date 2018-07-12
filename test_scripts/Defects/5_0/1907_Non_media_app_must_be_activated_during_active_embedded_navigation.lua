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
local common = require('test_scripts/Defects/commonDefects')

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Variables ]]
local function activate_app(pAppId, self)
  self, pAppId = common.getSelfAndParams(pAppId, self)
  if not pAppId then pAppId = 1 end
  local mobSession = common.getMobileSession(self, pAppId)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  EXPECT_HMIRESPONSE(requestId)
  mobSession:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

local function onEventChange(self)
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "EMBEDDED_NAVI", isActive = true})
  self.mobileSession1:ExpectNotification("OnHMIStatus",
  { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
  { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  :Times(2)
  :Do(function(exp)
    if exp.occurences == 1 then
      self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName = "EMBEDDED_NAVI", isActive = false})
      local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(1) })
       EXPECT_HMIRESPONSE(requestId)
    end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_n)
runner.Step("Activate App", activate_app)

runner.Title("Test")
runner.Step("onEventChange EMBEDDED_NAVI true", onEventChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
