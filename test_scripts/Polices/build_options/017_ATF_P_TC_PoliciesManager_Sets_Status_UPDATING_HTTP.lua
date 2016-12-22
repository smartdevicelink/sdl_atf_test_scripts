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

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

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
  local message_order = 1
  local is_test_fail = false

  self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(function()

      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP"})
      :Do(function()
          if(message_order ~= 2) then
            commonFunctions:printError("OnSystemRequest is not received as message 2 after OnAppRegistered. Received as message: "..message_order)
            is_test_fail = true
          else
            print("OnSystemRequest received as message 2 after OnAppRegistered.")
          end
          message_order = message_order + 1
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = "PolicyTableUpdate", },"files/ptu.json")
          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)

      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
        { status = "UPDATE_NEEDED" }, {status = "UPDATING"}):Times(2)
      :Do(function(_,data)
          if(data.params.status == "UPDATE_NEEDED") then
            if(message_order ~= 1) then
              commonFunctions:printError("SDL.OnStatusUpdate(UPDATE_NEEDED) is not received as message 1 after OnAppRegistered. Received as message: "..message_order)
              is_test_fail = true
            else
              print("SDL.OnStatusUpdate(UPDATING) received as message 1 after OnAppRegistered.")
            end
            message_order = message_order + 1
          elseif(data.params.status == "UPDATING") then
            if(message_order ~= 3) then
              commonFunctions:printError("SDL.OnStatusUpdate(UPDATING) is not received as message 3 after OnAppRegistered. Received as message: "..message_order)
              is_test_fail = true
            else
              print("SDL.OnStatusUpdate(UPDATING) received as message 3 after OnAppRegistered.")
            end
            message_order = message_order + 1
          end
        end)

      if(is_test_fail == true) then
        self:FailTestCase("Test is FAILED. See prints.")
      end

    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
