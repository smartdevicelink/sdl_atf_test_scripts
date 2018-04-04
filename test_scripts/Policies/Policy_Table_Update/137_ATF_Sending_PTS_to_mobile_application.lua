---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Sending PTS to mobile application
-- [HMI API] SystemRequest request/response
--
-- Description:
-- SDL must forward OnSystemRequest(request_type=PROPRIETARY, url, appID) with encrypted PTS
-- snapshot as a hybrid data to mobile application with <appID> value. "fileType" must be
-- assigned as "JSON" in mobile app notification.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- 2. Performed steps
-- HMI->SDL:BasicCommunication.OnSystemRequest ('url', requestType:PROPRIETARY, appID)
--
-- Expected result:
-- SDL->app: OnSystemRequest ('url', requestType:PROPRIETARY, fileType="JSON", appID)
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('cardinalities')
require('user_modules/AppTypes')

local HMIAppID

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
end
function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:RAI()
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })
  :Times(0)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Times(0)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function(_, d1)
      HMIAppID = d1.params.application.appID
    end)
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(
    function()
      self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      self.mobileSession:ExpectNotification("OnPermissionsChange")
      :Times(1)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Trigger_getting_device_consent()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppID })
  EXPECT_HMIRESPONSE(requestId1)
  :Do(
    function(_, d1)
      if d1.result.isSDLAllowed ~= true then
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(requestId2)
        :Do(
          function()
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(
              function(_, d2)
                self.hmiConnection:SendResponse(d2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
                self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
              end)
          end)
      end
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }):Times(2)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(
    function(_, d)
      self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
      local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
      EXPECT_HMIRESPONSE(requestId)
      :Do(
        function()
          local policy_file_name = "PolicyTableUpdate"
          self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })
          self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
