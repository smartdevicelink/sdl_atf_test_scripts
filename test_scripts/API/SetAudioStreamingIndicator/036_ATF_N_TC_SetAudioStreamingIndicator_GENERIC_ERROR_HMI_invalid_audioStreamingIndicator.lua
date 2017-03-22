---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetAudioStreamingIndicator] SDL must transfer request from mobile app to HMI in case no any failures
-- [GENERIC_ERROR]: SDL behavior in case HMI sends invalid response AND SDL must transfer this response to mobile app
-- [MOBILE_API] SetAudioStreamingIndicator
-- [HMI_API] [MOBILE_API] AudioStreamingIndicator enum
-- [HMI_API] SetAudioStreamingIndicator
-- [PolicyTable] SetAudioStreamingIndicator RPC
--
-- Description:
-- In case HMI sends invalid response by any reason that SDL must transfer to mobile app
-- SDL must:
-- log the error internally
-- respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
--
-- 1. Used preconditions
-- structure of invalid cases for audioStreamingIndicator: wrong type, not existing value, missing
-- Allow SetAudioStreamingIndicator RPC by policy
-- Register and activate media application
--
-- 2. Performed steps
-- Send SetAudioStreamingIndicator(audioStreamingIndicator = "PAUSE")
-- HMI->SDL: UI.SetAudioStreamingIndicator(resultcode: "SUCCESS", audioStreamingIndicator = invalid)
-- audioStreamingIndicator has wrong value: invalid(taken from structure)
--
-- Expected result:
-- SDL->HMI: UI.SetAudioStreamingIndicator(audioStreamingIndicator = "PAUSE")
-- SDL->mobile: SetAudioStreamingIndicator_response("GENERIC_ERROR", success:false, info:"Invalid message received from vehicle")
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

--[[ Local variables ]]
local invalid_data = {
  -- wrong type: integer
  {value = 123, descr = "wrongtype"},
  {value = "TESTING" , descr = "nonexisting_enum"},
  {value = nil, descr = "missing"}
}

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

for i = 1, #invalid_data do
  Test["TestStep_GENERIC_ERROR_audioStreamingIndicator_PAUSE_HMI_replies_" .. invalid_data[i].descr] = function(self)
    local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PAUSE" })

    EXPECT_HMICALL("UI.SetAudioStreamingIndicator", { audioStreamingIndicator = "PAUSE" })
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { audioStreamingIndicator = invalid_data[i].value })
    end)

    EXPECT_RESPONSE(corr_id, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })
  end
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