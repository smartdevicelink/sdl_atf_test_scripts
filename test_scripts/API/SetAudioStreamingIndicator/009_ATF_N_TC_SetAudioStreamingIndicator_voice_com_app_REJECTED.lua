---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetAudioStreamingIndicator] SDL must respond REJECTED to non-media app (navi, voice-com)
-- [MOBILE_API] SetAudioStreamingIndicator
-- [HMI_API] [MOBILE_API] AudioStreamingIndicator enum
-- [PolicyTable] SetAudioStreamingIndicator RPC
--
-- Description:
-- In case voice-com app sends the SetAudioStreamingIndicator_request to SDL
-- SDL must: respond "REJECTED, success:false" to this voice-com app
--
-- 1. Used preconditions
-- Allow SetAudioStreamingIndicator RPC by policy
-- Register and activate first voice-com application, isMediaApplication = false
-- Register and activate second voice-com application, isMediaApplication = true
--
-- 2. Performed steps
-- Send SetAudioStreamingIndicator(audioStreamingIndicator = "PLAY")
--
-- Expected result:
-- For first and second application:
-- SDL->mobile: SetAudioStreamingIndicator_response(REJECTED, success:false)
-- SDL must NOT transfer this SetAudioStreamingIndicator_request to HMI
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"}
config.application2.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"}

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local mobile_session = require('mobile_session')

--[[ General Precondition before ATF start ]]
testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"}, "SetAudioStreamingIndicator")
commonSteps:DeleteLogsFiles()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_ActivateApp()
  commonSteps:ActivateAppInSpecificLevel(self, self.applications[config.application1.registerAppInterfaceParams.appName])
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL"})
end

function Test:Precondition_StartSecondSession()
	self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
	self.mobileSession1:StartService(7)
end

function Test:Preconditon_RegisterSecondApplication()
  local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName }})
  :Do(function(_,data) self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID end)

  self.mobileSession1:ExpectResponse(CorIdRegister, { success=true, resultCode = "SUCCESS"})
	self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:Precondition_ActivateSecondApp()
  commonSteps:ActivateAppInSpecificLevel(self, self.applications[config.application2.registerAppInterfaceParams.appName])
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "BACKGROUND"})
  self.mobileSession1:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep1_SetAudioStreamingIndicator_REJECTED_PLAY_ismedia_app_false()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PLAY" })
  EXPECT_HMICALL("UI.SetAudioStreamingIndicator",{}):Times(0)

  EXPECT_RESPONSE(corr_id, { success = false, resultCode = "REJECTED"})
end

function Test:TestStep2_SetAudioStreamingIndicator_REJECTED_PLAY_ismedia_app_true()
  local corr_id = self.mobileSession1:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PLAY" })
  EXPECT_HMICALL("UI.SetAudioStreamingIndicator",{}):Times(0)

  self.mobileSession1:ExpectResponse(corr_id, { success = false, resultCode = "REJECTED"})
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
