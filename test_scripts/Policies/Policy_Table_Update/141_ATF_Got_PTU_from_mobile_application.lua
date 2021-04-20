---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Got PTU from mobile application
-- [HMI API] SystemRequest request/response
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
-- 2. Performed steps
-- app->SDL:SystemRequest(requestType=PROPRIETARY)
--
-- Expected result:
-- SDL->HMI: SystemRequest(requestType=PROPRIETARY, fileName, appID)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

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
function Test:TestStep_Sending_PTS_to_mobile_application()
  local is_test_fail = false
  local hmi_app_id = self.applications[config.application1.registerAppInterfaceParams.appName]
  print("hmi_app_id = " ..hmi_app_id)
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId,{result = {code = 0, method = "SDL.GetPolicyConfigurationData" } })
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"})
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY", fileType = "JSON" })
      :Do(function(_,_)
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"}, "files/ptu.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest",{
              requestType = "PROPRIETARY",
              fileName = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate",
              appID = hmi_app_id})
          :Do(function(_,_data1)
              self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              --self.hmiConnection:SendNotification ("SDL.OnReceivedPolicyUpdate", { policyfile = SystemFilesPath.."/PolicyTableUpdate"})
            end)

          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)

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
