---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [OnAppInterfaceUnregistered] "APP_UNAUTHORIZED" in case of failed nickname validation after updated policies
--
-- Description:
-- SDL should be case-insensetive when comparing the value of "appID"
-- received within RegisterAppInterface against the value(s) of "app_policies" section.
--
-- Preconditions:
-- 1. Local PT contains <appID> section (for example, appID="0000001") in "app_policies"
-- 2. App with appID="0000001" and appName="Test Application" is registered to SDL.
-- 3. SDL.OnStatusUpdate = "UP_TO_DATE"
-- Steps:
-- 1. Initiate a Policy Table Update (for example, by registering an application with <appID>
-- non-existing in LocalPT) (ex. appID="123_abc").
-- 2. Ensure the Updated PT has a different "nicknames" for appID="0000001"
-- 3. Verify the reason of OnAppInterfaceUnregistered notification for appID="0000001"
--
-- Expected result:
-- SDL checks updated polices for currently registered application with appID="123_abc" ->
-- currently registered appName is different from value in policy table ->
-- SDL->app: OnAppInterfaceUnregistered (APP_UNAUTHORIZED)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local testCasesForPolicyAppIdManagament = require("user_modules/shared_testcases/testCasesForPolicyAppIdManagament")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")
local mobileSession = require("mobile_session")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_trigger_getting_device_consent()
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
  config.application2.registerAppInterfaceParams.appName = "App1"
  config.application2.registerAppInterfaceParams.fullAppID = "123_abc"
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "App1" }})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

function Test:UpdatePolicy()
  local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("module_config.timeout_after_x_seconds")
  local seconds_between_retries = {}
  for i = 1, #testCasesForPolicyTableSnapshot.seconds_between_retries do
    seconds_between_retries[i] = testCasesForPolicyTableSnapshot.seconds_between_retries[i].value
  end

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
    {
      file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json",
      timeout = timeout_after_x_seconds,
      retry = seconds_between_retries
    })
  :Do(function(_,data1)
      self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
      testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/appID_Management/ptu_1.json")
    end)
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", { reason = "APP_UNAUTHORIZED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
