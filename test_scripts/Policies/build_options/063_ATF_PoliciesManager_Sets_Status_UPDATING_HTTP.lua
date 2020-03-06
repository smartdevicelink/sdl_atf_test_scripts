---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] PoliciesManager changes status to “UPDATING”
-- [HMI API] OnStatusUpdate
--
-- Description:
-- PoliciesManager must change the status to “UPDATING” and notify HMI with
-- OnStatusUpdate("UPDATING") right after SnapshotPT is sent out to to mobile
-- app via OnSystemRequest() RPC.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:HTTP, appID="default")
--
-- 2. Performed steps
-- SDL->app: OnSystemRequest ('url', requestType:HTTP, fileType="JSON", appID)
-- Expected result:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATING) right after SDL->app: OnSystemRequest
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

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

function Test:TestStep_PoliciesManager_changes_status_UPDATING()

  self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_NOTIFICATION("OnSystemRequest")--, {requestType = "LOCK_SCREEN_ICON_URL"}, {requestType = "HTTP"})
  :Do(function(_,data)
      print("SDL -> MOB: OnSystemRequest, requestType: " .. data.payload.requestType)
    end)
  :Times(2)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(function()

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate"):Times(2)
  :Do(function(exp,data)
      print("SDL -> HMI: OnStatusUpdate, status: " .. data.params.status)
      if(data.params.status == "UPDATE_NEEDED" and exp.occurences ~= 1) then
        self:FailTestCase("SDL.OnStatusUpdate(UPDATE_NEEDED) is not received for first OnStatusUpdate, Received at occurences: " .. exp.occurences)
      elseif(data.params.status == "UPDATING" and exp.occurences ~= 2) then
        self:FailTestCase("SDL.OnStatusUpdate(UPDATING) is not received for second OnStatusUpdate, Received at occurences: " .. exp.occurences)
      end
    end)
  end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
