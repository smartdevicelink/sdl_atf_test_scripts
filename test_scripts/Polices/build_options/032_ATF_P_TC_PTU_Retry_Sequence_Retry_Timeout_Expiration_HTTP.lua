--UNREADY: Need to add json file from https://github.com/smartdevicelink/sdl_atf_test_scripts/pull/363/
-- Also the sequence array is filled in with BasicCommunication.OnSystemRequest
-- r_actual also returns nil and this invalidates the whole check

---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] Local Policy Table retry timeout expiration
--
-- Description:
-- In case the corresponding retry timeout expires, PoliciesManager must send
-- the new PTU request to mobile app until successful Policy Table Update has finished
-- or the number of retry attempts is limited by the number of elements
-- in "seconds_between_retries" section of LPT.
--
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application 1 is registered and activated
-- PTU with updated 'timeout_after_x_seconds' and 'seconds_between_retries' params
-- is performed to speed up the test
-- PTU finished successfully (UP_TO_DATE)
-- 2. Performed steps
-- Trigger new PTU by registering Application 2
-- SDL -> mobile BC.OnSystemRequest (params, url)
-- PTU does not come within defined timeout
-- Check timestamps of BC.PolicyUpdate() requests
-- Calculate timeouts
--
-- Expected result:
-- Timeouts correspond to 'timeout_after_x_seconds' and 'seconds_between_retries' params
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/build_options/retry_seq.json")
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Local variables ]]
local time_system_request_prev = 0
local time_system_request_curr = 0

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Connect_device()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_OnStatusUpdate_UPDATE_NEEDED_new_PTU_request()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = config.application1.registerAppInterfaceParams.appName } })
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, {status = "UPDATING"}):Times(2)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP"})
  :Do(function()
    time_system_request_prev = timestamp()
  end)

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Retry_Timeout_Expiration()
  local is_test_fail = false
  local timeout_after_x_seconds = 30
  local time_wait = {}
  local sec_btw_ret = {1, 2, 3, 4, 5}
  local total_time

  time_wait[1] = timeout_after_x_seconds
  time_wait[2] = sec_btw_ret[1] + timeout_after_x_seconds
  time_wait[3] = sec_btw_ret[1] + sec_btw_ret[2] + timeout_after_x_seconds
  time_wait[4] = sec_btw_ret[2] + sec_btw_ret[3] + timeout_after_x_seconds
  time_wait[5] = sec_btw_ret[3] + sec_btw_ret[4] + timeout_after_x_seconds
  time_wait[6] = sec_btw_ret[4] + sec_btw_ret[5] + timeout_after_x_seconds
  total_time = (time_wait[1] + time_wait[2] + time_wait[3] + time_wait[4] + time_wait[5] + time_wait[6])*1000

  local function verify_retry_sequence(occurences)
    local time_1 = time_system_request_curr
    local time_2 = time_system_request_prev
    local timeout = (time_1 - time_2)

    if (time_wait[occurences] == nil) then
      time_wait[occurences]  = time_wait[6]
      commonFunctions:printError("ERROR: OnSystemRequest is received more than expected.")
      is_test_fail = true
    end

    if( ( timeout > (time_wait[occurences]*1000 + 2000) ) or ( timeout < (time_wait[occurences]*1000 - 2000) )) then
      is_test_fail = true
      commonFunctions:printError("ERROR: timeout for retry sequence "..occurences.." is not as expected: "..(time_wait[occurences]*1000).."msec(2sec tolerance). real: "..timeout.."ms")
    else
      print("timeout is as expected for retry sequence "..occurences..": "..(time_wait[occurences]*1000).."ms. real: "..timeout)
    end
    return true
  end

  if(time_wait == 0) then time_wait = 63000 end

  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "HTTP", fileType = "JSON"}):Timeout(total_time+60000):Times(5)
  :Do(function(exp)
    if(time_system_request_curr ~= 0) then
      time_system_request_prev = time_system_request_curr
    end
    time_system_request_curr = timestamp()
    verify_retry_sequence(exp.occurences)
  end)

  commonTestCases:DelayedExp(total_time)
  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test