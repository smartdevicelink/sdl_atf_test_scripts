-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/2323
--
-- Description:
-- SDL must set media app to FULL and NOT_AUDIBLE in case this app is activated during phone call
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) Media app is registered.
--
-- Steps to reproduce:
-- 1) HMI sends OnEventChanged(PHONE_CALL, isActive=true)
-- 2) SDL receives SDL.ActivateApp(<appID_of_media_app>) request from HMI during phone call
-- SDL does:
--  a. respond SDL.ActivateApp(SUCCESS) to HMI
--  b. send OnHMIStatus(FULL, NOT_AUDIBLE) to mobile app
-- 3) HMI sends OnEventChanged(PHONE_CALL, isActive=false)
-- SDL does:
--  a. send OnHMIStatus(FULL, AUDIBLE) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local Functions ]]
local function activationPhoneCall(self)
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "PHONE_CALL", isActive = true })
  self.mobileSession1:ExpectNotification("OnHMIStatus")
  :Times(0)
end

local function activate_app(self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  EXPECT_HMIRESPONSE(requestId)

  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Times(2)
  :Do(function(exp)
    if exp.occurences == 1 then
      self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
        { eventName = "PHONE_CALL", isActive = false })
    end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_n)

runner.Title("Test")
runner.Step("Activate phone call", activationPhoneCall)
runner.Step("Activate application", activate_app)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
