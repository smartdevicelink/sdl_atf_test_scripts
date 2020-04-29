---------------------------------------------------------------------------------------------
-- Requirement summary:
-- Registering the app the 1st time initiate promting the User about the event
-- [RegisterAppInterface] Order of request/response/notifications on registering an application
--
-- Description:
-- When the application is registered for the first time (no records in PT) PoliciesManager should not initiate promting the User about the event.
-- 1. Used preconditions:
-- a) Stop SDL and set SDL to first life cycle state.
-- 2. Performed steps:
-- a) Register Application
--
-- Expected result:
-- No prompts or notification are observed on HMI
-- Note: Requirement under clarification! Assumed that OnAppPermissionChanged and OnSDLConsentNeeded should not come
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')
local utils = require ('user_modules/utils')

--[[ General Preconditions before ATF starts ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
function Test:Precondition_ConnectMobile_FirstLifeCycle()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:TestStep_Firs_Time_Register_App_And_Check_That_No_Permission_Notification_To_HMI()
  local is_test_fail = false
  local order_communication = 1
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
        majorVersion = 3,
        minorVersion = 0
      },
      appName = "SPT",
      isMediaApplication = true,
      languageDesired = "EN-US",
      hmiDisplayLanguageDesired = "EN-US",
      appID = "1234567",
      deviceInfo =
      {
        os = "Android",
        carrier = "Megafon",
        firmwareRev = "Name: Linux, Version: 3.4.0-perf",
        osVersion = "4.4.2",
        maxNumberRFCOMMPorts = 1
      }
    })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {
      application =
      {
        appName = "SPT",
        policyAppID = "1234567",
        isMediaApplication = true,
        hmiDisplayLanguageDesired = "EN-US",
        deviceInfo =
        {
          name = utils.getDeviceName(),
          id = utils.getDeviceMAC(),
          transportType = utils.getDeviceTransportType(),
          isSDLAllowed = false
        }
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {}):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnSDLConsentNeeded", {}) :Times(0)

  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  :Do(function(_,_)
      if(order_communication ~= 1) then
        commonFunctions:printError("RAI response is not received 1 in message order. Real: received number: "..order_communication)
        is_test_fail = true
      end
      order_communication = order_communication + 1
    end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,_)
      if(order_communication ~= 2) then
        commonFunctions:printError("OnHMIStatus is not received 2 in message order. Real: received number: "..order_communication)
        is_test_fail = true
      end
      order_communication = order_communication + 1
    end)

  EXPECT_NOTIFICATION("OnPermissionsChange", {})
  :Do(function(_,_)
      if(order_communication ~= 3) then
        commonFunctions:printError("OnPermissionsChange is not received 3 in message order. Real: received number: "..order_communication)
        is_test_fail = true
      end

      order_communication = order_communication + 1
    end)

  local function verify_test_result()
    if(is_test_fail == true) then
      self:FailTestCase("Test is FAILED. See prints.")
    end
  end
  RUN_AFTER(verify_test_result,10000)
  commonTestCases:DelayedExp(11000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
