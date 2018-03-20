---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetAudioStreamingIndicator] Conditions for SDL must respond IGNORED to media app
-- [MOBILE_API] SetAudioStreamingIndicator
-- [HMI_API] [MOBILE_API] AudioStreamingIndicator enum
-- [PolicyTable] SetAudioStreamingIndicator RPC
--
-- Description:
-- In case media app is already set to <AudioStreamingIndicator> and the same media app sends
-- SetAudioStreamingIndicator_request with the same <AudioStreamingIndicator>
-- SDL must: respond with IGNORED, success:false to mobile app
-- SDL must NOT: transfer this SetAudioStreamingIndicator_request to HMI
--
-- 1. Used preconditions
-- Allow SetAudioStreamingIndicator RPC by policy
-- Register and activate media application
-- Send SetAudioStreamingIndicator(audioStreamingIndicator = "PLAY")
--
-- 2. Performed steps
-- Send again SetAudioStreamingIndicator(audioStreamingIndicator = "PLAY")
--
-- Expected result:
-- SDL->mobile: SetAudioStreamingIndicator_response(IGNORED, success:false)
-- SDL must NOT transfer this SetAudioStreamingIndicator_request to HMI
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

function Test:Precondition_SetAudioStreamingIndicator_SUCCESS_PLAY()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PLAY" })

  EXPECT_HMICALL("UI.SetAudioStreamingIndicator", { audioStreamingIndicator = "PLAY" })
  :Do(function(_,data) self.hmiConnection:SendResponse (data.id, data.method, "SUCCESS") end)

  EXPECT_RESPONSE(corr_id, { success = true, resultCode = "SUCCESS"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_SetAudioStreamingIndicator_IGNORED_PLAY()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PLAY" })
  EXPECT_HMICALL("UI.SetAudioStreamingIndicator",{}):Times(0)

  EXPECT_RESPONSE(corr_id, { success = false, resultCode = "IGNORED"})
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