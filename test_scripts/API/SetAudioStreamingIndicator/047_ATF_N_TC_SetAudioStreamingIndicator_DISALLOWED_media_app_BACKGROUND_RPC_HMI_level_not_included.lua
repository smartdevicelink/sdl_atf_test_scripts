---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GeneralResultCodes] DISALLOWED in case app's current HMI Level is not listed in assigned policies
-- [MOBILE_API] SetAudioStreamingIndicator
-- [HMI_API] [MOBILE_API] AudioStreamingIndicator enum
-- [PolicyTable] SetAudioStreamingIndicator RPC
--
-- Description:
-- In case Policy Table doesn't contain current application's HMILevel defined in Policy Table
-- "functional_groupings" section for a specified RPC,
-- PoliciesManager must return DISALLOWED resultCode and success:"false" to this RPC requested by the application.
--
-- 1. Used preconditions
-- Allow SetAudioStreamingIndicator RPC by policy for HMI levels: "LIMITED", "NONE", "FULL"
-- Register and activate media application.
-- Register and activate second media app.
-- First app is deactivated to HMI level = "BACKGROUND"
--
-- 2. Performed steps
-- Send SetAudioStreamingIndicator(audioStreamingIndicator = "PAUSE")
--
-- Expected result:
-- SDL->mobile: SetAudioStreamingIndicator_response("DISALLOWED", success:false)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local mobile_session = require('mobile_session')

--[[ General Precondition before ATF start ]]
testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"LIMITED", "NONE", "FULL"}, "SetAudioStreamingIndicator")
commonSteps:DeleteLogsFiles()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_ActivateApp()
  commonSteps:ActivateAppInSpecificLevel(self, self.applications[config.application1.registerAppInterfaceParams.appName])
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
end

function Test:Precondition_StartSession_App2()
	config.application2.registerAppInterfaceParams.appHMIType = {"MEDIA"}
	config.application2.registerAppInterfaceParams.isMediaApplication = true
	self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection, config.application2.registerAppInterfaceParams)
end

function Test:Precondition_RegisterMedia_App2()
  self.mobileSession2:StartService(7)
  :Do(function()
		local corr_id = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID
		end)

		self.mobileSession2:ExpectResponse(corr_id, {success = true, resultCode = "SUCCESS"})
		self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
   end)
end

function Test:Precondition_ActivateMedia_App2()
	commonSteps:ActivateAppInSpecificLevel(self, self.applications[config.application2.registerAppInterfaceParams.appName])
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "BACKGROUND"})
  self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_SetAudioStreamingIndicator_DISALLOWED_audioStreamingIndicator_PAUSE()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PAUSE" })

  EXPECT_HMICALL("UI.SetAudioStreamingIndicator", {}):Times(0)
  EXPECT_RESPONSE(corr_id, { success = false, resultCode = "DISALLOWED" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_preloaded_file()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test