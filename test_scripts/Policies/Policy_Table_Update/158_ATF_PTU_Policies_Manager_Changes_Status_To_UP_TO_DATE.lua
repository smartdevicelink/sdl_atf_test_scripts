---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] PoliciesManager changes status to “UP_TO_DATE”
-- [HMI API] OnStatusUpdate
--
-- Description:
-- PoliciesManager must change the status to “UP_TO_DATE” and notify HMI with OnStatusUpdate("UP_TO_DATE")
-- right after successful validation of received PTU.
--
-- Steps:
-- 1. Register new app
-- 2. Trigger PTU
-- 3. SDL->HMI: Verify step of SDL.OnStatusUpdate(UP_TO_DATE) notification in PTU sequence
--
-- Expected result:
-- SDL.OnStatusUpdate(UP_TO_DATE) notification is send right after successful validation of received PTU
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Precondition")

function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_CheckMessagesSequence_UpToDate()
  local is_test_fail = false
  local message_number = 1
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath").."/"
  local corIdSystemRequest

  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
    if(message_number ~= 1) then
      commonFunctions:printError("Error: SDL.GetPolicyConfigurationData reponse is not received as message 1 after SDL.GetPolicyConfigurationData request. Real: "..message_number)
      is_test_fail = true
    else
      print("SDL.GetPolicyConfigurationData is received as message "..message_number.." after SDL.GetPolicyConfigurationData request")
    end
    message_number = message_number + 1
    self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"})
  end)

  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
  :Do(function(_, _)
    if( (message_number ~= 2) and (message_number ~= 3)) then
      commonFunctions:printError("Error: OnSystemRequest reponse is not received as message 2/3 after SDL.GetPolicyConfigurationData request. Real: "..message_number)
      is_test_fail = true
    else
      print("OnSystemRequest is received as message "..message_number.." after SDL.GetPolicyConfigurationData request")
    end
    message_number = message_number + 1
    corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"}, "files/ptu.json")
    EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
  end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :Do(function(exp,data)
    if(exp.occurences == 1) then
      if (message_number ~= 4) then
        commonFunctions:printError("Error: SDL.OnStatusUpdate("..data.params.status..")  response is not received as message 4 after SDL.GetPolicyConfigurationData request. Real: "..message_number)
        is_test_fail = true
      else
        print("SDL.OnStatusUpdate("..data.params.status..") is received as message "..message_number.." after SDL.GetPolicyConfigurationData request")
      end
    else
      commonFunctions:printError("Error: SDL.OnStatusUpdate("..data.params.status..")  response is not received as message "..message_number.." after SDL.GetPolicyConfigurationData request")
    end
    message_number = message_number + 1
  end)

  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Do(function(_, data)
    if( (message_number ~= 3)) then
      commonFunctions:printError("Error: BasicCommunication.SystemRequest response is not received as message 3 after SDL.GetPolicyConfigurationData request. Real: "..message_number)
      is_test_fail = true
    else
      print("BasicCommunication.SystemRequest is received as message "..message_number.." after SDL.GetPolicyConfigurationData request")
    end
    message_number = message_number + 1
    self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
    self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", {policyfile = policy_file_path .. "PolicyTableUpdate"})
  end)

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
