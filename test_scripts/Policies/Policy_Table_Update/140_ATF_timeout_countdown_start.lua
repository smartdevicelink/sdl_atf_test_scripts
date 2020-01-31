---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] "timeout" countdown start
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
-- Do not send SystemRequest from <app_ID>
--
-- Expected result:
-- SDL waits for SystemRequest response from <app ID> within 'timeout' value, if no obtained,
-- it starts retry sequence
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
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
  local time_update_needed = {}
  local time_system_request = {}
  local is_test_fail = false
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local PathToSnapshot = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local file_pts = SystemFilesPath.."/"..PathToSnapshot

  local seconds_between_retries = {}
  local timeout_pts = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
  for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
    seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
  end
  local time_wait = (timeout_pts*seconds_between_retries[1]*1000 + 2000)
  commonTestCases:DelayedExp(time_wait) -- tolerance 10 sec

  local expUrls = commonFunctions:getUrlsTableFromPtFile(file_pts)
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId,{result = {code = 0, method = "SDL.GetPolicyConfigurationData"} })
  :ValidIf(function(_,data)
      return commonFunctions:validateUrls(expUrls, data)
    end)
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ requestType = "PROPRIETARY", fileName = "PolicyTableUpdate" })
      --first retry sequence

      local function verify_retry_sequence(occurences)
        --time_update_needed[#time_update_needed + 1] = testCasesForPolicyTable.time_trigger
        time_update_needed[#time_update_needed + 1] = timestamp()
        local time_1 = time_update_needed[#time_update_needed]
        local time_2 = time_system_request[#time_system_request]
        local timeout = (time_1 - time_2)
        if( ( timeout > (timeout_pts*1000 + 2000) ) or ( timeout < (timeout_pts*1000 - 2000) )) then
          is_test_fail = true
          commonFunctions:printError("ERROR: timeout for retry sequence "..occurences.." is not as expected: "..timeout_pts.."msec(5sec tolerance). real: "..timeout.."ms")
        else
          print("timeout is as expected for retry sequence "..occurences..": "..timeout_pts.."ms. real: "..timeout)
        end
        return true
      end

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY", fileType = "JSON"})
      :Do(function(_,_) time_system_request[#time_system_request + 1] = timestamp() end)

      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}):Times(1):Timeout(64000)
      :Do(function(exp_pu, data)
          print(exp_pu.occurences..":"..data.params.status)
          if(data.params.status == "UPDATE_NEEDED") then
            verify_retry_sequence(exp_pu.occurences - 1)
          end
        end)

      --TODO(istoimenova): Remove when "[GENIVI] PTU is restarted each 10 sec." is fixed.
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate"):Times(0)
      :Do(function(_,data)
          is_test_fail = true
          commonFunctions:printError("ERROR: PTU sequence is restarted again!")
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
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
