---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Local Policy Table retry sequence start
--
-- Description:
-- In case PoliciesManager does not receive the Updated PT during time defined in
-- "timeout_after_x_seconds" section of Local PT, it must start the retry sequence.
-- The HMI does not provide a url so Core must use the urls included in the policy table.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
-- Application not in PT is registered -> PTU is triggered
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
--
-- 2. Performed steps
-- HMI -> SDL: SDL.GetURLs (<service>)
-- HMI->SDL: BasicCommunication.OnSystemRequest (requestType: PROPRIETARY)
-- SDL->app: OnSystemRequest (<url 1>, requestType:PROPRIETARY, fileType="JSON")
--
-- Expected result:
-- Timeout expires and retry sequence started with next url in endpoint array
-- SDL->app: OnSystemRequest (<url 2>, requestType:PROPRIETARY, fileType="JSON")
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local mobile_session = require('mobile_session')
local atf_logger = require('atf_logger')

--[[ Local variables ]]
local time_prev = 0
local time_curr = 0
local exp_timeout = 8000
local tolerance = 500 -- ms

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/build_options/retry_seq_url_array.json")

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
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"})
  :Do(function(exp, data)
      print("[" .. atf_logger.formated_time(true) .. "] " .. "SDL->HMI: SDL.OnStatusUpdate()" .. ": " .. exp.occurences .. ": " .. data.params.status)
      if (exp.occurences == 2) and (data.params.status == "UPDATING") then
        time_prev = timestamp()
      end
    end)
  :Times(2)

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function()
      print("[" .. atf_logger.formated_time(true) .. "] " .. "SDL->HMI: BC.PolicyUpdate")
      local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
          { policyType = "module_config", property = "endpoints" })
      EXPECT_HMIRESPONSE(requestId)
      :Do(function()
          local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
          local pts_file_name = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
          self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_path .. pts_file_name })
          self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY", url = "http://policies.telematics.ford.com/api/policies/1" })
        end)
    end)
end

function Test:TestStep_RetrySequenceStart()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"})
  :Do(function(exp, data)
      print("[" .. atf_logger.formated_time(true) .. "] " .. "SDL->HMI: SDL.OnStatusUpdate()" .. ": " .. exp.occurences .. ": " .. data.params.status)
      if (exp.occurences == 1) and (data.params.status == "UPDATE_NEEDED") then
        time_curr = timestamp()
        local act_timeout = time_curr - time_prev
        print("Timeout between retries: " .. act_timeout .. "ms")
        if (act_timeout > exp_timeout + tolerance) or (act_timeout < exp_timeout - tolerance) then
          self:FailTestCase("Timeout for retry sequence is not as expected: " .. exp_timeout .. "ms (" .. tolerance .. "ms tolerance)")
        end
      end
    end)
  :Times(2)
  :Timeout(15000)

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate"):Times(0)
  self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" , url = "http://policies.telematics.ford.com/api/policies/2"}):Times(1)
  :Timeout(15000)

  commonTestCases:DelayedExp(15000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_files()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
