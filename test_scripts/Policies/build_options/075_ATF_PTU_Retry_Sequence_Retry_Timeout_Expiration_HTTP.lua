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
-- Preconditions:
-- 1. SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- 2. LPT is updated: params 'timeout_after_x_seconds' and 'seconds_between_retries' in order to speed up the test
-- 3. SDL is started
-- 4. Application is registered
--
-- Steps:
-- 1. PTU is triggered
-- 2. SDL -> mobile: BC.OnSystemRequest (params, url)
-- 3. PTU does not come within defined timeout
-- 4. SDL -> mobile: BC.OnSystemRequest (params, url)
-- 5. Check number of retries
--
-- Expected result:
-- Number of retries corresponds to number of elements in 'seconds_between_retries' array
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
    end)
  :Times(11)
  :Timeout(total_time)

  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP", fileType = "BINARY"})
  :Do(function(_, data)
      print("[" .. atf_logger.formated_time(true) .. "] " .. "SDL->MOB: OnSystemRequest()", data.payload.requestType)
    end)
  :Times(5)
  :Timeout(total_time)

  commonTestCases:DelayedExp(total_time)
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
