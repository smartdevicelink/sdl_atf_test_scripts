---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1909
--
-- Description:
-- SDL must set LIMITED HMILevel in case app was activated during postponed HMILevel resumption
--
-- In case:
-- 1) SDL and HMI are started.
-- 2) Media app is registered
-- 3) Media app is resuming after unexpected disconnect.
-- 4) HMILevel resumption of media app was postponed and SDL receives SDL.ActivateApp (<appID_of_media_app>).
--
-- Expected result:
-- 1) SDL must respond SDL.ActivateApp(SUCCESS) to HMI resume HMILevel of media app after event ends activate app
-- and send OnHMIStatus (LIMITED, AUDIBLE) to this media app.
--
-- Information: non-media apps:
-- a. can be activated during active phone call
-- b. can not be activated during OnEmergencyEvent (enabled=true) or active VR session
-- (as there is no way to activate it during these events)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Local Functions ]]
local function deactivateAppToLimited()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId() })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function unexpectedDisconnect()
  common.getMobileSession():Stop()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = true })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    test.mobileSession[1] = nil
  end)
end

local function activatePhoneCall()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "PHONE_CALL", isActive = true })
end

local function checkResumptionHMILevel()
  local function onResumeNotification()
    common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
      { eventName = "PHONE_CALL", isActive = false })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnResumeAudioSource",
      { appID = common.getHMIAppId() })
  end
  RUN_AFTER(onResumeNotification, 4000)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Deactivate app to limited", deactivateAppToLimited)

runner.Title("Test")
runner.Step("Unexpected disconnect app", unexpectedDisconnect)
runner.Step("Activate phone call", activatePhoneCall)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("checkResumptionHMILevel", checkResumptionHMILevel)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
