---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] Conditions for SDL to provide the default value of "steeringWheelLocation" param to each app in response
-- [HMI_capabilities] The 'hmi_capabilities' struct
-- [MOBILE_API] [HMI_API] The 'steeringWheelLocation' enum
-- [MOBILE_API] The 'steeringWheelLocation' param
--
-- Description:
-- In case SDL does NOT receive value of "steeringWeelLocation" parameter via UI.GetCapabilities_response from HMI
-- SDL must retrieve the value of "steeringWeelLocation" parameter from "HMI_capabilities.json" file and 
-- provide the value of "steeringWeelLocation" via RegisterAppInterface_response to mobile app
--
-- 1. Used preconditions
-- In InitHMI_OnReady HMI replies with parameter message with invalid character only space in json message to UI.GetCapabilities
-- SDL invalidates message
-- Get value of "steeringWeelLocation" parameter from "HMI_capabilities.json".
--
-- 2. Performed steps
-- Register new application.
--
-- Expected result:
-- SDL->mobile: RegisterAppInterface_response steeringWeelLocation is provided equal to "HMI_capabilities.json"
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForRAI = require('user_modules/shared_testcases/testCasesForRAI')
local events = require("events")
local mobile_session = require('mobile_session')

--[[ Local variables ]]
local value_steering_wheel_location = testCasesForRAI.get_data_steeringWheelLocation()

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_initHMI')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_InitHMI_OnReady()
	testCasesForRAI.InitHMI_onReady_without_UI_GetCapabilities(self)
	local event = events.Event()
	event.level = 2
	event.matches = function(_, data) return data.method == "UI.GetCapabilities" end

	EXPECT_HMIEVENT(event, "UI.GetCapabilities")
	:Do(function(_,data)
		self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"UI.GetCapabilities"}, "message":"  ","code":11}}')
	end)
end

function Test:Precondition_connectMobile()
	self:connectMobile()
end

function Test:Precondition_StartSession()
	self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
	self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_RAI_steeringWheelLocation()
	local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
		
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName=config.application1.registerAppInterfaceParams.appName }})
	EXPECT_RESPONSE(CorIdRegister, { success=true, resultCode = "SUCCESS", hmiCapabilities = { steeringWheelLocation = value_steering_wheel_location } })
	EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
