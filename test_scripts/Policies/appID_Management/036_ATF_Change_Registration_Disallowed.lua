---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [ChangeRegistration]: DISALLOWED in case app sends appName non-existing in app-specific policies
--
-- Description:
-- SDL should respond with (DISALLOWED, success:false) in case app_specific policies are assigned to app
-- AND this app sends ChangeRegistration request with "appName" that does not exist in "nicknames" field in PolicyTable
--
-- Preconditions:
-- 1. Local PT contains <appID> section (for example, appID="123_xyz") in "app_policies"
-- with nickname = "Media Application"
-- 2. appID="123_xyz" is registered to SDL
-- 3. SDL.OnStatusUpdate = "UP_TO_DATE"
-- Steps:
-- 1. Send ChangeRegistration RPC for appID="123_xyz" with appName = "fghj"
-- 2. Verify status of response
--
-- Expected result:
-- Response has the following data: success = false, resultCode = "DISALLOWED"
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local testCasesForPolicyAppIdManagament = require("user_modules/shared_testcases/testCasesForPolicyAppIdManagament")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Pecondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:Precondition_UpdatePolicy()
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_0.json")
end

function Test:Precondition_StartNewSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:Precondition_RegisterNewApp()
  config.application2.registerAppInterfaceParams.appName = "Media Application"
  config.application2.registerAppInterfaceParams.fullAppID = "123_xyz"
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_ChangeRegistration()
  local corId = self.mobileSession2:SendRPC("ChangeRegistration", {
      language = "EN-GB",
      hmiDisplayLanguage = "EN-GB",
      appName = "fghj"
    })
  self.mobileSession2:ExpectResponse(corId, { success = false, resultCode = "DISALLOWED" })

  self.mobileSession2:ExpectNotification("OnAppInterfaceUnregistered", {}):Times(0)
  commonTestCases:DelayedExp(10000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
