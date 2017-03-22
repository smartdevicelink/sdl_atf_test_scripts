---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] PTS creation rule
--
-- Description:
-- SDL should request PTU in case new application is registered and is not listed in PT
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Connect mobile phone over WiFi.
-- 2. Performed steps
-- Register new application
--
-- Expected result:
-- PTU is requested. PTS is created.
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

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
  local is_test_passed = true
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = config.application1.registerAppInterfaceParams.appName } })
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, {status = "UPDATING"}):Times(2)
  :Do(function(_,data)
    if(data.params.status == "UPDATE_NEEDED") then
      is_test_passed = testCasesForPolicyTableSnapshot:verify_PTS(true,
              { config.application1.registerAppInterfaceParams.appID, config.application2.registerAppInterfaceParams.appID, },
              {config.deviceMAC},
              {""},
              "print")
    end
  end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP"})

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

  if(is_test_passed == false) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test