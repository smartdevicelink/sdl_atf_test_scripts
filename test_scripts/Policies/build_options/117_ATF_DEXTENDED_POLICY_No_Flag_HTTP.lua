---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Support of "http" flow of Policy Table Update
--
-- Description:
-- In case SDL is built with -DEXTENDED_POLICY: HTTP" flag SDL must support
--"http" (normal) PolicyTableUpdate flow

-- 1. Performed steps
-- Build SDL with flag above
--
-- Expected result:
-- SDL is successfully built
-- The flag -DEXTENDED_POLICY: is set to HTTP
-- PTU passes successfully
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_Connect_device()
  self:connectMobile()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Trigger_HTTP_RAI()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      local RequestIDRai1 = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = config.application1.registerAppInterfaceParams.appName } })
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, {status = "UPDATING"}):Times(2)

      self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LOCK_SCREEN_ICON_URL"}, {requestType = "HTTP"}):Times(2)
      self.mobileSession:ExpectResponse(RequestIDRai1, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
end

function Test:TestStep_HTTP_Flow_AfterBuild ()
  commonFunctions:check_ptu_sequence_partly(self, "files/ptu.json", "PolicyTableUpdate")
  --testCasesForPolicyTable:flow_PTU_SUCCEESS_HTTP(self)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
