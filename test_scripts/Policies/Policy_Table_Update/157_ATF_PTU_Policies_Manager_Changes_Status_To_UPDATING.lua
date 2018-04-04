---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] PoliciesManager changes status to "UPDATING"
-- [HMI API] OnStatusUpdate
--
-- Description:
-- PoliciesManager must change the status to "UPDATING" and notify HMI with OnStatusUpdate("UPDATING")
-- right after SnapshotPT is sent out to to mobile app via OnSystemRequest() RPC.
--
-- Steps:
-- 1. Register new app
-- 2. Trigger PTU
-- 3. SDL->HMI: Verify step of SDL.OnStatusUpdate(UPDATING) notification in PTU sequence
--
-- Expected result:
-- SDL.OnStatusUpdate(UPDATING) notification is send right after SDL->MOB: OnSystemRequest
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

function Test:TestStep_CheckMessagesSequence()
  local is_test_fail = false
  local message_number = 1
  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId_GetUrls)
  :Do(function(_,_)
    self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"})

    if(message_number ~= 1) then
      commonFunctions:printError("Error: SDL.GetURLS reponse is not received as message 1 after SDL.GetURLS request. Real: "..message_number)
      is_test_fail = true
    else
      print("SDL.GetURLS is received as message "..message_number.." after SDL.GetURLS request")
    end
    message_number = message_number + 1
  end)

  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
  :Do(function(_,_)
    if( (message_number ~= 2) and (message_number ~= 3)) then
      commonFunctions:printError("Error: SDL.OnStatusUpdate reponse is not received as message 2/3 after SDL.GetURLS request. Real: "..message_number)
      is_test_fail = true
    else
      print("OnSystemRequest is received as message "..message_number.." after SDL.GetURLS request")
    end
    message_number = message_number + 1
  end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",{status = "UPDATING"})
  :Do(function(_,data)
    if( (message_number ~= 2) and (message_number ~= 3)) then
      commonFunctions:printError("Error: SDL.OnStatusUpdate reponse is not received as message 2/3 after SDL.GetURLS request. Real: "..message_number)
      is_test_fail = true
    else
      print("SDL.OnStatusUpdate("..data.params.status..") is received as message "..message_number.." after SDL.GetURLS request")
    end
    message_number = message_number + 1
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
