---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] SDL.ActivateApp from HMI, the device this app is running on is CONSENTED
-- [HMI API] SDL.ActivateApp (Genivi)
--
-- Description:
-- SDL receives request for app activation from HMI and the device the app is running on is consented by the User
-- 1. Used preconditions:
-- Connect unconsented device
-- Register 1st application
-- Activate 1st application
-- Add session 2
-- Register 2nd application
--
-- 2. Performed steps
-- Activate 2nd application
--
-- Expected result:
-- PoliciesManager must respond with "isSDLAllowed: true" in the response to HMI without consent request
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_ActivateApp1_isSDLAllowed_false()
  local is_test_fail = false
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId,
    {result = { code = 0, isAppPermissionsRevoked = false, isAppRevoked = false, isSDLAllowed = false, isPermissionsConsentNeeded = false, method ="SDL.ActivateApp"}})
  :Do(function(_,data)
      --App is not allowed so consent for device is needed
      if data.result.isSDLAllowed ~= false then
        commonFunctions:printError("Error: wrong behavior of SDL - device needs to be not consented on HMI")
        is_test_fail = true
      else
        local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestId1)
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,_data1)
                self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
          end)
      end

    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
  :Do(function(_,_)
      if(is_test_fail == true) then
        self:FailTestCase("Test is FAILED. See prints.")
      end
    end)
end

function Test:TestStep_AddSession2()
  self.mobileSession1 = mobile_session.MobileSession(self,self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:TestStep_RegisterApp2()
  local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      self.HMIAppID2 = data.params.application.appID
    end)
  self.mobileSession1:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:TestStep_ActivateApp2_isSDLAllowed_true()
  local is_test_fail = false
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID2 })
  EXPECT_HMIRESPONSE(RequestId,
    {result = { code = 0, isAppPermissionsRevoked = false, isAppRevoked = false, isPermissionsConsentNeeded = false, isSDLAllowed = true, method ="SDL.ActivateApp"}})
  :Do(function(_,data)
      --Device is consented already, so no consent is needed:
      if data.result.isSDLAllowed ~= true then
        commonFunctions:printError("Error: wrong behavior of SDL - device already consented")
        is_test_fail = true
      else
        self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
      end
    end)

  EXPECT_NOTIFICATION("OnHMIStatus", {})

  self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
  :Do(function(_,_)
      if(is_test_fail == true) then
        self:FailTestCase("Test is FAILED. See prints.")
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
