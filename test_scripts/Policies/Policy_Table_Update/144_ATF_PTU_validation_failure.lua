---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] PTU validation failure
-- [HMI API] OnStatusUpdate
-- [HMI API] OnReceivedPolicyUpdate notification
--
-- Description:
-- SDL must forward OnSystemRequest(request_type=PROPRIETARY, url, appID) with encrypted PTS
-- snapshot as a hybrid data to mobile application with <appID> value. "fileType" must be
-- assigned as "JSON" in mobile app notification.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetPolicyConfigurationData (policyType = "module_config", property = "endpoints")
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:PROPRIETARY, appID="default")
-- SDL->app: OnSystemRequest ('url', requestType:PROPRIETARY, fileType="JSON", appID)
-- app->SDL: SystemRequest(requestType=PROPRIETARY)
-- SDL->HMI: SystemRequest(requestType=PROPRIETARY, fileName, appID)
-- HMI->SDL: SystemRequest(SUCCESS)
-- 2. Performed steps
-- HMI->SDL: OnReceivedPolicyUpdate(policy_file): policy_file with missing mandatory seconds_between_retries.
--
-- Expected result:
-- SDL->HMI: OnStatusUpdate(UPDATE_NEEDED)
-- SDL removes 'policyfile' from the directory
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')
local utils = require ('user_modules/utils')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU_validation_failure()
  local is_test_fail = false
  local hmi_app_id = self.applications[config.application1.registerAppInterfaceParams.appName]

  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId,{result = {code = 0, method = "SDL.GetPolicyConfigurationData" } } )
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ fileName = "PolicyTableUpdate", requestType = "PROPRIETARY" })
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY", fileType = "JSON" })
      :Do(function(_,_)
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"},
          "files/jsons/Policies/PTU_ValidationRules/invalid_PTU_missing_seconds_between_retries.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest",{
              requestType = "PROPRIETARY",
              fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate",
              appID = hmi_app_id})
          :Do(function(_,_data1)
              self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})

              EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
              :Do(function(_,_)
                  if( commonSteps:file_exists("/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate") == true) then
                    is_test_fail = true
                    commonFunctions:printError("File /tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate exists!")
                  end
                end)
            end)

          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

function Test:Wait_3s()
  commonTestCases:DelayedExp(3000)
end

function Test:TestStep_CheckSDLLogError()
  local is_test_fail = false

  --TODO(istoimenova): Update in case specific rule how errors to be printed is created
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("policy_table.policy_table.device_data:")--" should be omitted in PT_UPDATE")
  if (result == false) then
    commonFunctions:printError("Error: message 'policy_table.policy_table.device_data: should be ommited in PT_UPDATE' is not observed in smartDeviceLink.log.")
    is_test_fail = true
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("policy_table.policy_table.module_config.seconds_between_retries:")-- object is not initialized")
  if (result == false) then
    commonFunctions:printError("Error: message 'policy_table.policy_table.module_config.seconds_between_retries: object is not initialized' is not observed in smartDeviceLink.log.")
    is_test_fail = true
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("policy_table.policy_table.module_meta:")-- should be ommited in PT_UPDATE")
  if (result == false) then
    commonFunctions:printError("Error: message 'policy_table.policy_table.module_meta: should be ommited in PT_UPDATE' is not observed in smartDeviceLink.log.")
    is_test_fail = true
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("policy_table.policy_table.usage_and_error_counts:")-- should be ommited in PT%_UPDATE")
  if (result == false) then
    commonFunctions:printError("Error: message 'policy_table.policy_table.usage_and_error_counts: should be ommited in PT_UPDATE' is not observed in smartDeviceLink.log.")
    is_test_fail = true
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not valid.")
  if (result == false) then
    commonFunctions:printError("Error: message 'Policy table is not valid.' is not observed in smartDeviceLink.log.")
    is_test_fail = true
  end

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end

end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
