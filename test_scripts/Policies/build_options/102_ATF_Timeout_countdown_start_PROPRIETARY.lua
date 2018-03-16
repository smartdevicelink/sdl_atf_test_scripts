-- Requirements summary:
-- [PolicyTableUpdate] "timeout" countdown start
--
-- Description:
-- SDL must forward OnSystemRequest(request_type=PROPRIETARY, url, appID) with encrypted PTS
-- snapshot as a hybrid data to mobile application with <appID> value. "fileType" must be
-- assigned as "JSON" in mobile app notification.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
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
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ Local Functions ]]
local function timestamp()
  local f = io.popen("date +%s")
  local o = f:read("*all")
  f:close()
  return (o:gsub("\n", ""))
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Sending_PTS_to_mobile_application()
  local time_system_request = {}
  local is_test_fail = false

  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId_GetUrls)
  :Do(function()
    self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ requestType = "PROPRIETARY", fileName = "PolicyTableUpdate" })
    --first retry sequence
    local seconds_between_retries = {}
    local timeout_pts = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
    for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
      seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
    end
    local time_wait = (timeout_pts*seconds_between_retries[1]*1000 + 10000)
    local function verify_retry_sequence()
      local time_1 = timestamp() -- time PolicyUpdate
      local time_2 = time_system_request[#time_system_request]
      local timeout = (time_1 - time_2)
      if( ( timeout > (timeout_pts + 2) ) or ( timeout < (timeout_pts - 2) )) then
        is_test_fail = true
        commonFunctions:printError("ERROR: timeout for first retry sequence is not as expected: "..timeout_pts.." sec (5 sec tolerance). real: "..timeout.." sec")
      else
        print("timeout is as expected: "..timeout_pts.." sec. real: "..timeout)
      end
    end
    EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY", fileType = "JSON"})
    :Do(function() time_system_request[#time_system_request + 1] = timestamp() end)
    EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
    :Do(function(exp,data)
      if(exp.occurences > 1) then
        is_test_fail = true
        commonFunctions:printError("ERROR: PTU sequence is restarted again!")
      end
      verify_retry_sequence()
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    :Timeout(time_wait)
  end)

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Force_Stop_SDL()
  StopSDL()
end

return Test
