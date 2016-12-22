-- Requirements summary:
-- [PolicyTableUpdate][GENIVI] PoliciesManager changes status to “UPDATE_NEEDED”
--
-- Description:
-- PoliciesManager must change the status to “UPDATE_NEEDED” and notify HMI with OnStatusUpdate(“UPDATE_NEEDED”)
-- in case the timeout taken from "timeout_after_x_seconds" field of LocalPT or "timeout between retries"
-- is expired before PoliciesManager receives SystemRequest with PTU from mobile application.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Connect mobile phone over WiFi.
-- 2. Performed steps
-- Register new application to trigger PTU
-- SDL-> <app ID> ->OnSystemRequest(params, url, )
-- Timeout expires
--
-- Expected result:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_ChangeStatus_Update_Needed()
  local time_update_needed = {}
  local time_system_request = {}
  local endpoints = {}
  local is_test_fail = false
  local timeout_pts = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
  local seconds_between_retries = {}
  print(#testCasesForPolicyTableSnapshot)
  for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
    seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
  end
  local time_wait = (timeout_pts*seconds_between_retries[1]*1000)

  local function verify_retry_sequence()
    time_update_needed[#time_update_needed + 1] = timestamp()
    local time_1 = time_update_needed[#time_update_needed]
    local time_2 = time_system_request[#time_system_request]
    local timeout = (time_1 - time_2)
    if( ( timeout > (timeout_pts*1000 + 2000) ) or ( timeout < (timeout_pts*1000 - 2000) )) then
      is_test_fail = true
      commonFunctions:printError("ERROR: timeout for first retry sequence is not as expected: "..timeout_pts.."msec(5sec tolerance). real: "..timeout.."ms")
    else
      print("timeout is as expected: "..tostring(timeout_pts*1000).."ms. real: "..timeout)
    end
  end

  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId_GetUrls,{result = {code = 0, method = "SDL.GetURLS", urls = endpoints} } )
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ requestType = "HTTP", fileName = "PolicyTableUpdate" })

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "HTTP", fileType = "JSON"}):Timeout(12000)
      :Do(function(_,_) time_system_request[#time_system_request + 1] = timestamp() end)
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"}, {status = "UPDATE_NEEDED"}):Times(2):Timeout(time_wait)
      :Do(function(_,data)
          if(data.params.status == "UPDATE_NEEDED" ) then
            --first retry sequence
            verify_retry_sequence()
          end
        end)
    end)

  commonTestCases.DelayedExp(time_wait)

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Stop()
  StopSDL()
end

return Test
