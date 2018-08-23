---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2459
--
-- Description:
-- SDL must respond UNSUPPORTED_RESOURCE to mobile app in case SDL 4.0 feature is required to be ommited in implementation
-- Precondition:
-- Values configured in .ini file:
-- AppSavePersistentDataTimeout =10000;
-- ResumptionDelayBeforeIgn = 30;
-- ResumptionDelayAfterIgn = 30;
-- ApplicationResumingTimeout = 5000
-- Core and HMI are started.
-- Non-media application(COMMUNIATION) is registered and activated. -> HMI level = FULL
-- Go to menu Apps. HMI level of application becomes LIMITED
-- Stop WiFi connection.
-- In case:
-- 1) Press "Go To CD" -> HMI sends OnEventChanged(AUDIO_SOURCE, isActive: true) notification to SDL.
-- 2) Activate WiFi connection
-- 3) Wait ApplicationResumingTimeout to expire.
-- Expected result:
-- 1) SDL must resume HMILevel for non-media app.
-- Actual result:
-- HMI level becomes BACKGROUND, audioStreamingState : NOT_AUDIBLE
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local test = require("user_modules/dummy_connecttest")
local mobile_session = require('mobile_session')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "COMMUNICATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function updateINIFile()
    commonFunctions:write_parameter_to_smart_device_link_ini("AppSavePersistentDataTimeout", 10000)
    commonFunctions:write_parameter_to_smart_device_link_ini("ResumptionDelayBeforeIgn", 30)
    commonFunctions:write_parameter_to_smart_device_link_ini("ResumptionDelayAfterIgn", 30)
    commonFunctions:write_parameter_to_smart_device_link_ini("ApplicationResumingTimeout", 5000)
end

local function hmiLevelLIMITED()
	common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
	common.getMobileSession():ExpectNotification("OnHMIStatus",
	{ hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function closeSession()
	common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
	test.mobileConnection:Close()
end

local function onEventChange()
	common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
	{ eventName = "AUDIO_SOURCE", isActive = true})
end

local function openConnection()
	test.mobileSession[1] = mobile_session.MobileSession( test, test.mobileConnection,
		config.application1.registerAppInterfaceParams)
		test.mobileConnection:Connect()
		test.mobileSession[1]:StartRPC()
	:Do(function()
		commonTestCases:DelayedExp(5000)
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
			{appID = common.getHMIAppId(), unexpectedDisconnect = true}):Times(0)
	end)
end

local function cleanSessions()
    for i = 1, common.getAppsCount() do
      test.mobileSession[i]:Stop()
      test.mobileSession[i] = nil
    end
    utils.wait()
end

local function resumingApp()
	common.getHMIConnection():ExpectNotification("BasicCommunication.OnResumeAudioSource", { appID = common.getHMIAppId() })
	common.getMobileSession():ExpectNotification("OnHMIStatus",
	{ hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("updateINIFile", updateINIFile)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU, { 1 })
runner.Step("Activate App", common.activateApp, { 1 })
runner.Step("Hmi level LIMITED", hmiLevelLIMITED)
runner.Step("Application disconnect", closeSession)

-- [[ Test ]]
runner.Title("Test")
runner.Step("onEventChange", onEventChange)
runner.Step("Open session", openConnection)
runner.Step("Clean session", cleanSessions)
runner.Step("Register App", common.registerAppWOPTU, { 1 })
runner.Step("Check resuming app", resumingApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
