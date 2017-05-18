---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] "timeout" countdown start
-- [HMI API] SystemRequest request/response
--
-- Description:
--PoliciesManager must start timeout taken from "timeout_after_x_seconds" field of LocalPT
--right after OnSystemRequest is sent out to mobile app.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- 2. Performed steps
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:HTTP, appID="default")
-- SDL->app: OnSystemRequest ('url', requestType:HTTP, fileType="JSON", appID)
-- SDL->HMI: SDL.OnStatusUpdate(UPDATING)
--
-- Expected result:
--SDL waits for SystemRequest response from <app ID> within 'timeout' value,
--if no obtained, it starts retry sequence
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Local variables ]]
local time_system_request_first = 0

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
    time_system_request_first = timestamp()
  end)

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Sending_PTS_to_mobile_application()
  local time_system_request = {}
  local is_test_fail = false
  local timeout_pts


  local seconds_between_retries = {}
  --TODO(istoimenova): Should be removed when "[GENIVI] HTTP: sdl_snapshot.json is not saved to file system" is fixed.
  if ( commonSteps:file_exists( '/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json') ) then
    timeout_pts = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
    for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
      seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
    end
  else
    timeout_pts = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("module_config.timeout_after_x_seconds")
    for i = 1, #testCasesForPolicyTableSnapshot.seconds_between_retries do
      seconds_between_retries[i] = testCasesForPolicyTableSnapshot.seconds_between_retries[i].value
    end
  end

  local time_wait = (timeout_pts*seconds_between_retries[1]*1000 + 2000)
  commonTestCases:DelayedExp(time_wait) -- tolerance 10 sec

  local function verify_retry_sequence(occurences)
  --time_updating[#time_updating + 1] = testCasesForPolicyTable.time_trigger

    local time_1 = time_system_request[#time_system_request]
    local time_2 = time_system_request_first
    local timeout = (time_1 - time_2)

    if( ( timeout > (timeout_pts*1000 + 2000) ) or ( timeout < (timeout_pts*1000 - 2000) )) then
      is_test_fail = true
      commonFunctions:printError("ERROR: timeout for retry sequence "..occurences.." is not as expected: "..(timeout_pts*1000).."msec(5sec tolerance). real: "..timeout.."ms")
    else
      print("timeout is as expected for retry sequence "..occurences..": "..(timeout_pts*1000).."ms. real: "..timeout)
    end
    return true
  end

  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "HTTP", fileType = "JSON"})
  :Do(function()
    time_system_request[#time_system_request + 1] = timestamp()
    verify_retry_sequence(1)
  end)

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
