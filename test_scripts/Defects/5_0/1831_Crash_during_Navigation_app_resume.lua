---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1831
--
-- Description:
-- Crash during Navigation app resume
-- Precondition:
-- Core and HMI are started.
-- Navigation application is registered and activated. -> HMI level = FULL
-- In case:
-- 1) BC.ActivateApp is sent from SDL to HMI
-- 2) Once the HMI gives the response to the BC.ActivateApp,
--    then there is a crash observed in state_controller_impl.cc where below mentioned DCHECK is failing.
-- Expected result:
-- 1) SDL must resume Navigation app
-- Actual result:
-- Crash during Navigation app resume
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local test = require("user_modules/dummy_connecttest")
local mobile_session = require('mobile_session')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local utils = require("user_modules/utils")
local events = require("events")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function closeConnection()
	common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
	test.mobileConnection:Close()
end

local function openConnection()
	test.mobileConnection:Connect()
	EXPECT_EVENT(events.connectedEvent, "Connected")
	:Do(function()
		utils.cprint(35, "Mobile connected")
	  end)
  end
  

local function cleanSessions()
    for i = 1, common.getAppsCount() do
      test.mobileSession[i] = nil
    end
    utils.wait()
end

local function checkResumingActivationApp()
    common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {appID = common.getHMIAppId()})
    :Do(function(_,data)
        common.getHMIConnection():SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
    common.getMobileSession():ExpectNotification("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU, { 1 })
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Application disconnect", closeConnection)
runner.Step("Clean session", cleanSessions)
runner.Step("Open session", openConnection)
runner.Step("Register App", common.registerAppWOPTU, { 1 })
runner.Step("Resuming Activation App", checkResumingActivationApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
