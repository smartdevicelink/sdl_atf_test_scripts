---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetAudioStreamingIndicator] SDL must transfer request from mobile app to HMI in case no any failures
-- [MOBILE_API] SetAudioStreamingIndicator
-- [HMI_API] [MOBILE_API] AudioStreamingIndicator enum
-- [HMI_API] SetAudioStreamingIndicator
-- [PolicyTable] SetAudioStreamingIndicator RPC
--
-- Description:
-- In case media app sends the valid SetAudioStreamingIndicator_request to SDL
-- and this request is allowed by Policies
-- SDL must:
-- transfer SetAudioStreamingIndicator_request to HMI
-- respond with <resultCode> received from HMI to mobile app (please see table 'Expected resultCodes from HMI' below)
--
-- 1. Used preconditions
-- Allow SetAudioStreamingIndicator RPC by policy
-- Register and activate media application
--
-- 2. Performed steps
-- Send SetAudioStreamingIndicator(audioStreamingIndicator = "PLAY_PAUSE")
-- HMI->SDL: UI.SetAudioStreamingIndicator(resultcode: "SUCCESS", fake parameter)
--
-- Expected result:
-- SDL->HMI: UI.SetAudioStreamingIndicator(audioStreamingIndicator = "PLAY_PAUSE")
-- SDL->mobile: SetAudioStreamingIndicator_response("SUCCESS", success:true)
-- fake parameter is ignored
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

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_SetAudioStreamingIndicator_SUCCESS_audioStreamingIndicator_PLAY_PAUSE_fakeparam()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", {audioStreamingIndicator = "PLAY_PAUSE"})

  EXPECT_HMICALL("UI.SetAudioStreamingIndicator", { audioStreamingIndicator = "PLAY_PAUSE" })
  :Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {available = true})
  end)

  EXPECT_RESPONSE(corr_id, { success = true, resultCode = "SUCCESS"})
  :ValidIf (function(_,data)
    if data.payload.availabe then
      commonFunctions:printError("SDL resends fake parameter available to mobile app!")
      return false
    else
      return true
    end
  end)
  EXPECT_NOTIFICATION("OnHashChange",{}):Times(0)
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