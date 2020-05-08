---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] Nickname validation must be done before duplicate name validation
--
-- Description:
-- SDL should return RegisterAppInterface's response (DISALLOWED, success: false)
-- in case the application sends RegisterAppInterface request with the "appName" value that:
-- > is not listed in this app's specific policies
-- > is the same as another already-registered application has
--
-- Preconditions:
-- 1. Local PT contains <appID> section in "app_policies" for:
-- - appID="0000001", appName = "App1"
-- - appID="123_xyz", appName = "MediaApp"
-- 2. appID="0000001" is registered to SDL
-- 3. appID="123_xyz" is not registered to SDL yet
-- 4. SDL.OnStatusUpdate = "UP_TO_DATE"
-- Steps:
-- 1. Register new application with appID="123_xyz" and appName = "App1"
-- 2. Verify that SDL's response
--
-- Expected result:
-- SDL returns RegisterAppInterface's response (DISALLOWED, success: false)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local testCasesForPolicyAppIdManagament = require("user_modules/shared_testcases/testCasesForPolicyAppIdManagament")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
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

function Test:UpdatePolicy()
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_0.json")
end

function Test:StartNewSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:RegisterNewApp()
  config.application2.registerAppInterfaceParams.appName = "INCORRECT_NAME"
  config.application2.registerAppInterfaceParams.fullAppID = "123_xyz"
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  self.mobileSession2:ExpectResponse(corId, { success = false, resultCode = "DISALLOWED" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
