---------------------------------------------------------------------------------------------
-- Description:
-- SDL receives request for app activation from HMI and the device the app is running on is consented by the User
-- 1. Used preconditions:
-- Close current connection
-- Overwrite preloaded Policy Table to ensure device is not preconsented.
-- Connect device
-- Register 1st application
--
-- 2. Performed steps
-- Activate 1st application
-- Consent device
-- Add new session
-- Register 2nd application
-- Activate 2nd application
--
-- Requirement summary:
-- [UpdateDeviceList] isSDLAllowed:true
-- [HMI API] BasicCommunication.UpdateDeviceList request/response
--
-- Expected result:
-- PoliciesManager must respond with "isSDLAllowed: true" in the response to HMI without consent request
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

function Test:ConnectDevice()
  local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    {
      deviceList = {
        {
          id = config.deviceMAC,
          isSDLAllowed = false,
          name = ServerAddress,
          transportType = "WIFI"
        }
      }
    }
    ):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function Test:RegisterApp1()
  commonTestCases:DelayedExp(3000)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID = data.params.application.appID
        end)
      self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:ActivateApp1()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID})
  EXPECT_HMIRESPONSE(RequestId,
    {result = { code = 0, isAppPermissionsRevoked = false, isAppRevoked = false, isSDLAllowed = false, isPermissionsConsentNeeded = false, method ="SDL.ActivateApp"}})
  :Do(function(_,data)
      --App is not allowed so consent for device is needed
      if data.result.isSDLAllowed ~= false then
        commonFunctions:userPrint(31, "Error: wrong behavior of SDL - device needs to be consented on HMI")
      else
        local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestId1)
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,_data1)
                self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
          end)
      end
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

function Test:AddSession2()
  self.mobileSession1 = mobile_session.MobileSession(self,self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:RegisterApp2()
  local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      self.HMIAppID2 = data.params.application.appID
    end)
  self.mobileSession1:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:ActivateApp2_isSDLAllowed_true()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID2 })
  EXPECT_HMIRESPONSE(RequestId,
    {result = { code = 0, isAppPermissionsRevoked = false, isAppRevoked = false, isPermissionsConsentNeeded = false, isSDLAllowed = true, method ="SDL.ActivateApp", priority ="NONE"}})
  :Do(function(_,data)
      --Device is consented already, so no consent is needed:
      if data.result.isSDLAllowed ~= true then
        commonFunctions:userPrint(31, "Error: wrong behavior of SDL - device already consented")
      else
        self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
      end
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {})
  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
