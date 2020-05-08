---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] Case-insensitivity of appName
--
-- Description:
-- SDL should be case-insensetive when comparing the value of "appName"
-- received within RegisterAppInterface against the value(s) of "nicknames" section
-- for the corresponding appID provided by the application.

-- Preconditions:
-- 1. Local PT contains <appID> section (for example, appID="123_xyz") in "app_policies"
-- with nickname = "MediaApp"
-- 2. appID="123_xyz" is not registered to SDL yet
-- 3. SDL.OnStatusUpdate = "UP_TO_DATE"
-- Steps:
-- 1. Register new application with appID="123_xyz" and nickname = "MediAAPP"
-- 2. Verify status of registeration
--
-- Expected result:
-- SDL must respond with the following data: success = true, resultCode = "SUCCESS"
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
  config.application2.registerAppInterfaceParams.appName = "MediAAPP"
  config.application2.registerAppInterfaceParams.fullAppID = "123_xyz"
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "MediAAPP" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
