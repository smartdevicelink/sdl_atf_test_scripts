---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] PoliciesManager changes status to “UPDATE_NEEDED”
--
-- Description:
-- PoliciesManager must change the status to “UPDATE_NEEDED” and notify HMI with
-- OnStatusUpdate(“UPDATE_NEEDED”) in case the timeout taken from "timeout_after_x_seconds" field
-- of LocalPT or "timeout between retries" is expired before PoliciesManager receives SystemRequest
-- with PTU from mobile application.
--
-- Preconditions:
-- 1. Register new app
-- 2. Activate app
-- Steps:
-- 1. Start PTU sequence
-- 2. Verify that SDL.OnStatusUpdate status changed: UPDATE_NEEDED -> UPDATING
-- 3. Sleep right after HMI->SDL: BC.SystemRequest for about 70 sec.
-- 4. Verify that SDL.OnStatusUpdate status changed: UPDATING -> UPDATE_NEEDED
--
-- Expected result:
-- Status of SDL.OnStatusUpdate notification changed: UPDATING -> UPDATE_NEEDED
--
-- TODO: Reduce value of timeout_after_x_seconds parameter in LPT in order to make test faster
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

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
function Test:TestStep_ChangeStatus_Update_Needed()
  local time_update_needed = {}
  local time_system_request = {}
  local is_test_fail = false
  local timeout_pts = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
  local seconds_between_retries = {}
  for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
    seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
  end
  if seconds_between_retries[1] == nil then
    self:FailTestCase("Problem with accessing in Policy table snapshot. Value not exists")
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
  EXPECT_HMIRESPONSE(RequestId_GetUrls)
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ requestType = "PROPRIETARY", fileName = "PolicyTableUpdate" })

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY", fileType = "JSON"}):Timeout(12000)
      :Do(function(_,_) time_system_request[#time_system_request + 1] = timestamp() end)

      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"}, {status = "UPDATE_NEEDED"}):Times(2):Timeout(time_wait+2000)
      :Do(function(_,data)
          if(data.params.status == "UPDATE_NEEDED" ) then
            --first retry sequence
            verify_retry_sequence()
          end
        end)
    end)

  commonTestCases:DelayedExp(time_wait)

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
