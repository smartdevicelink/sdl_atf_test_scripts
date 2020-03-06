---------------------------------------------------------------------------------------------
-- HTTP flow
-- Requirement summary:
-- [PolicyTableUpdate] Policy Table Update retry timeout computation
--
-- Description:
-- PoliciesManager must use the values from "seconds_between_retries" section of Local PT as the values to
-- computate the timeouts of retry sequense (that is, seconds to wait for the response).
--
-- Preconditions:
-- 1. SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- 2. LPT is updated: params 'timeout_after_x_seconds' and 'seconds_between_retries' in order to speed up the test
-- 3. SDL is started
-- 4. Application is registered

-- Steps:
-- 1. PTU is triggered
-- 2. SDL -> mobile: BC.OnSystemRequest (params, url)
-- 3. PTU does not come within defined timeout
-- 4. SDL -> mobile: BC.OnSystemRequest (params, url)
-- 5. Check durations between retries
--
-- Expected result:
-- Durations are the following
-- t[0] = timeout_after_x_seconds
-- t[1] = timeout_after_x_seconds + seconds_between_retries[1]
-- t[2] = timeout_after_x_seconds + seconds_between_retries[2] + t[1]
-- t[3] = timeout_after_x_seconds + seconds_between_retries[3] + t[2]
-- t[4] = timeout_after_x_seconds + seconds_between_retries[4] + t[3]
-- t[5] = timeout_after_x_seconds + seconds_between_retries[5] + t[4]
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local mobile_session = require('mobile_session')

--[[ Local variables ]]
local time_system_request_prev = 0
local time_system_request_curr = 0
local is_test_fail = false
local tolerance = 500 -- ms

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/build_options/retry_seq.json")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
require('user_modules/AppTypes')

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

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = config.application1.registerAppInterfaceParams.appName}})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)

  EXPECT_NOTIFICATION("OnSystemRequest")
  :Do(function(_, data)
      print("[" .. atf_logger.formated_time(true) .. "] " .. "SDL->MOB: OnSystemRequest()", data.payload.requestType)
      if data.payload.requestType == "HTTP" then
        time_system_request_prev = timestamp()
      end
    end)
  :Times(2)

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:TestStep_Retry_Timeout_Expiration()
  local timeout_after_x_seconds = 8
  local time_wait = {}
  local sec_btw_ret = {1, 2, 3, 4, 5}
  local total_time

  time_wait[0] = timeout_after_x_seconds -- 8
  time_wait[1] = timeout_after_x_seconds + sec_btw_ret[1] -- 8 + 1 = 9
  time_wait[2] = timeout_after_x_seconds + sec_btw_ret[2] + time_wait[1] -- 8 + 2 + 9 = 19
  time_wait[3] = timeout_after_x_seconds + sec_btw_ret[3] + time_wait[2] -- 8 + 3 + 19 = 30
  time_wait[4] = timeout_after_x_seconds + sec_btw_ret[4] + time_wait[3] -- 8 + 4 + 30 = 42
  time_wait[5] = timeout_after_x_seconds + sec_btw_ret[5] + time_wait[4] -- 8 + 5 + 42 = 55

  total_time = (time_wait[0] + time_wait[1] + time_wait[2] + time_wait[3] + time_wait[4] + time_wait[5]) * 1000 + 10000
  print("Waiting " .. total_time .. "ms")

  local function verify_retry_sequence(occurences)
    if time_system_request_curr ~= 0 then time_system_request_prev = time_system_request_curr end
    time_system_request_curr = timestamp()

    local timeout = (time_system_request_curr - time_system_request_prev)

    if (time_wait[occurences] == nil) then
      time_wait[occurences] = time_wait[5]
      commonFunctions:printError("ERROR: OnSystemRequest is received more than expected.")
      is_test_fail = true
    end

    if((timeout > (time_wait[occurences] * 1000 + tolerance)) or (timeout < (time_wait[occurences] * 1000 - tolerance))) then
      is_test_fail = true
      commonFunctions:printError("ERROR: timeout for retry sequence ".. occurences .. " is not as expected: "
        .. (time_wait[occurences] * 1000) .. "msec (" .. tolerance .. "ms tolerance). real: " .. timeout .. "ms")
    else
      print("Timeout is as expected for retry sequence ".. occurences .. ": " .. (time_wait[occurences] * 1000)
        .. "ms, real: " .. timeout)
    end
    return true
  end

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    {status = "UPDATE_NEEDED"}, {status = "UPDATING"},
    {status = "UPDATE_NEEDED"}, {status = "UPDATING"},
    {status = "UPDATE_NEEDED"}, {status = "UPDATING"},
    {status = "UPDATE_NEEDED"}, {status = "UPDATING"},
    {status = "UPDATE_NEEDED"}, {status = "UPDATING"},
    {status = "UPDATE_NEEDED"})
  :Do(function(exp, data)
      print("[" .. atf_logger.formated_time(true) .. "] " .. "SDL->HMI: SDL.OnStatusUpdate()"
        .. ": " .. exp.occurences .. ": " .. data.params.status)
      if exp.occurences == 11 and data.params.status == "UPDATE_NEEDED" then
        verify_retry_sequence(5)
      end
    end)
  :Times(11)
  :Timeout(total_time)

  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP", fileType = "BINARY"})
  :Do(function(exp, data)
      print("[" .. atf_logger.formated_time(true) .. "] " .. "SDL->MOB: OnSystemRequest()", data.payload.requestType)
      verify_retry_sequence(exp.occurences - 1)
    end)
  :Times(5)
  :Timeout(total_time)

  commonTestCases:DelayedExp(total_time)
end

function Test:VerifyResults()
  if (is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_files()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
