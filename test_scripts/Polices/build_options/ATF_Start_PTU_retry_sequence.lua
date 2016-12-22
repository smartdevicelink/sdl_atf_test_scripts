---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Local Policy Table retry sequence start
--
-- Description:
--      In case PoliciesManager does not receive the Updated PT during time defined in
--      "timeout_after_x_seconds" section of Local PT, it must start the retry sequence.
-- 1. Used preconditions
--      SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
--      Application not in PT is registered -> PTU is triggered
--      SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
--      SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
--      HMI -> SDL: SDL.GetURLs (<service>)
--      HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType: PROPRIETARY)
-- 2. Performed steps
--      SDL->app: OnSystemRequest ('url', requestType:PROPRIETARY, fileType="JSON")
-- Expected result:
--      Timeout expires and retry sequence started
--      SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--[TODO: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_RAI.lua")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_RAI')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_Connect_mobile()
  self:connectMobile()
end

function Test:Precondition_Start_new_session()
  self.mobileSession = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Start_Retry_Sequence_PROPRIETARY()
  local time_update_needed = {}
  local time_system_request = {}
  local endpoints = {}
  local is_test_fail = false
  local timeout_preloaded = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("module_config.timeout_after_x_seconds")
  local seconds_between_retries1 = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("module_config.seconds_between_retries.1")

  local time_wait = (timeout_preloaded*seconds_between_retries1*1000 + 2000)

  --first retry sequence
  local function verify_retry_sequence(occurences)
    time_update_needed[#time_update_needed + 1] = timestamp()
    local time_1 = time_update_needed[#time_update_needed]
    local time_2 = time_system_request[#time_system_request]
    local timeout = (time_1 - time_2)
    if( ( timeout > (timeout_preloaded*1000 + 2000) ) or ( timeout < (timeout_preloaded*1000 - 2000) )) then
      is_test_fail = true
      commonFunctions:printError("ERROR: timeout for retry sequence "..occurences.." is not as expected: "..timeout_preloaded.."msec(5sec tolerance). real: "..timeout.."ms")
    else
      print("timeout is as expected for retry sequence "..occurences..": "..tostring(timeout_preloaded*1000).."ms. real: "..timeout)
    end
    return true
  end

  self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.appName } })
  :Do(function(_,_)

      EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
      :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

        local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

        EXPECT_HMIRESPONSE(RequestId_GetUrls,{result = {code = 0, method = "SDL.GetURLS", urls = endpoints} } )
        :Do(function(_,_)
          self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ requestType = "PROPRIETARY", fileName = "PolicyTableUpdate" })

        EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY", fileType = "JSON"})
          :Do(function(_,_)
            time_system_request[#time_system_request + 1] = timestamp()
          end)
        end)
      end)
  end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
        {status = "UPDATE_NEEDED"}, {status = "UPDATING"}, {status = "UPDATE_NEEDED"}):Times(3):Timeout(time_wait)
  :Do(function(exp_pu, data)
    if(data.params.status == "UPDATE_NEEDED" and exp_pu.occurences > 1) then
      verify_retry_sequence(1)
    end
  end)
  commonTestCases:DelayedExp(time_wait)

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