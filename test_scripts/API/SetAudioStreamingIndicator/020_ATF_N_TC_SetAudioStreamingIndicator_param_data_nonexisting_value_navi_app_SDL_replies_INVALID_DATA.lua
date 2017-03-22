---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetAudioStreamingIndicator] SDL must transfer request from mobile app to HMI in case no any failures
-- [GeneralResultCodes] INVALID_DATA wrong type
-- [MOBILE_API] SetAudioStreamingIndicator
-- [HMI_API] [MOBILE_API] AudioStreamingIndicator enum
-- [PolicyTable] SetAudioStreamingIndicator RPC
--
-- Description:
-- In case media app sends the invalid SetAudioStreamingIndicator_request to SDL
-- and this request is allowed by Policies
-- SDL must NOT transfer SetAudioStreamingIndicator_request to HMI
-- SDL must respond with result code INVALID_DATA
--
-- 1. Used preconditions
-- Allow SetAudioStreamingIndicator RPC by policy
-- Register and activate navi application
--
-- 2. Performed steps
-- Send SetAudioStreamingIndicator(audioStreamingIndicator = "TESTING"),
-- audioStreamingIndicator has "TESTING": non existing value
--
-- Expected result:
-- SDL->mobile: SetAudioStreamingIndicator_response(INVALID_DATA, success:false)
-- SDL must NOT transfer this SetAudioStreamingIndicator_request to HMI
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}

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

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_SetAudioStreamingIndicator_INVALID_DATA_audioStreamingIndicator_nonexisting()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "TESTING" })
  EXPECT_HMICALL("UI.SetAudioStreamingIndicator",{}):Times(0)

  EXPECT_RESPONSE(corr_id, { success = false, resultCode = "INVALID_DATA"})
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