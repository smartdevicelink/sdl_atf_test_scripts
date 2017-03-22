---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetAudioStreamingIndicator] SDL must transfer request from mobile app to HMI in case no any failures
-- SDL must transfer all <resultCodes> received from HMI to mobile app
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
-- structure of all HMI result_codes, success: false is created
-- Allow SetAudioStreamingIndicator RPC by policy
-- Register and activate media application
--
-- 2. Performed steps
-- Send SetAudioStreamingIndicator(audioStreamingIndicator = "PAUSE")
-- Send second SetAudioStreamingIndicator(audioStreamingIndicator = "PAUSE")
-- HMI->SDL: UI.SetAudioStreamingIndicator(resultcode: hmi_result_code)
--
-- Expected result:
-- first request: SDL->HMI: UI.SetAudioStreamingIndicator(audioStreamingIndicator = "PAUSE")
-- first request: SDL->mobile: SetAudioStreamingIndicator_response(hmi_result_code, success:false)
-- second request: SDL->mobile: SetAudioStreamingIndicator_response("IGNORED", success:false)
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
-- in scope of the CRQ info parameter is not specified, but will be left for any future use.
local hmi_result_code = {
	{ result_code = "UNSUPPORTED_REQUEST", info = "" },
	{ result_code = "DISALLOWED", info = "" },
	{ result_code = "USER_DISALLOWED", info = "" },
	{ result_code = "REJECTED", info = "" },
	{ result_code = "ABORTED", info = "" },
	{ result_code = "IGNORED", info = "" },
	{ result_code = "IN_USE", info = "" },
	{ result_code = "DATA_NOT_AVAILABLE", info = "" },
	{ result_code = "TIMED_OUT", info = "" },
	{ result_code = "INVALID_DATA", info = "" },
	{ result_code = "CHAR_LIMIT_EXCEEDED", info = "" },
	{ result_code = "INVALID_ID", info = "" },
	{ result_code = "DUPLICATE_NAME", info = "" },
	{ result_code = "APPLICATION_NOT_REGISTERED", info = "" },
	{ result_code = "OUT_OF_MEMORY", info = "" },
	{ result_code = "TOO_MANY_PENDING_REQUESTS", info = "" },
	{ result_code = "GENERIC_ERROR", info = "" },
	{ result_code = "TRUNCATED_DATA", info = "" }
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

for i = 1, #hmi_result_code do
	Test["TestStep_SetAudioStreamingIndicator_"..hmi_result_code[i].result_code.."_audioStreamingIndicator_PAUSE"] = function(self)
		local corr_id_second_req
	  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PAUSE" })

	  EXPECT_HMICALL("UI.SetAudioStreamingIndicator", { audioStreamingIndicator = "PAUSE" })
	  :Do(function(_,data) 
	  	corr_id_second_req = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PAUSE" })
	  	
	  	local function send_HMI_response()
	  	  -- ATF issue: "Genivi: SDL doesn't accept some error_codes from HMI when they are sending with type of protocol_message "error""
	  		self.hmiConnection:SendError(data.id, data.method, hmi_result_code[i].result_code, "error message") 
	  	end
	  	
	  	RUN_AFTER(send_HMI_response, 1500)
		
		EXPECT_RESPONSE(corr_id_second_req, { success = false, resultCode = "IGNORED"})
	  end)
	  
	  EXPECT_RESPONSE(corr_id, { success = false, resultCode = hmi_result_code[i].result_code, info = "error message" })	  
	  EXPECT_NOTIFICATION("OnHashChange",{}):Times(0)
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