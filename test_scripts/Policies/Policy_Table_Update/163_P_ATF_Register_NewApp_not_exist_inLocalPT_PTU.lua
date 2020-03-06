-- Requirement summary:
-- [PolicyTableUpdate] New application has registered and doesn't yet exist in Local PT during PTU in progress
--
-- Description:
-- PoliciesManager must add the appID of the newly registered app to the Local PT in case
-- such appID does not yet exist in Local PT and PoliciesManager has sent the PT Snapshot and has not received the PT Update yet.
--
-- Performed steps
-- 1. MOB-SDL - Register Application default.
-- 2. PTU in progress. PoliciesManager has sent the PT Snapshot and has not received the PT Update yet
-- 3. MOB-SDL - app_2 -> SDL:RegisterAppInterface
-- 4. Check that both AppIds are present in Data Base.
--
-- Expected result:
-- SDL adds application with app_2 data into LocalPT according to general rules of adding app data into LocalPT
-------------------------------------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local Functions ]]
local registerAppInterfaceParams =
{
  syncMsgVersion =
  {
    majorVersion = 3,
    minorVersion = 0
  },
  appName = "Media Application",
  isMediaApplication = true,
  languageDesired = 'EN-US',
  hmiDisplayLanguageDesired = 'EN-US',
  appHMIType = {"NAVIGATION"},
  appID = "MyTestApp",
  deviceInfo =
  {
    os = "Android",
    carrier = "Megafon",
    firmwareRev = "Name: Linux, Version: 3.4.0-perf",
    osVersion = "4.4.2",
    maxNumberRFCOMMPorts = 1
  }
}

--[[ General Precondition before ATF start]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup ("Preconditions")

function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:Precondition_PolicyUpdateStarted()

  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{
          requestType = "PROPRIETARY",
          appID = self.applications [config.application1.registerAppInterfaceParams.appName],
          fileName = "sdl_snapshot.json"
        })
  end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
end

--[[ Test ]]
commonFunctions:newTestCasesGroup ("Test")
function Test:TestStep_OpenNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:TestStep_RAI_NewSession()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:TestStep_CheckThatAppID_BothApps_Present_In_DataBase()
  local is_test_fail = false
  local PolicyDBPath = tostring(config.pathToSDL) .. "/storage/policy.sqlite"
  os.execute(" sleep 2 ")

  local query = " select functional_group_id from app_group where application_id = '"..tostring(config.application1.registerAppInterfaceParams.fullAppID).."' "
  local AppId_1 = commonFunctions:get_data_policy_sql(PolicyDBPath, query)
  local AppIdValue_1
  for _,v in pairs(AppId_1) do
    AppIdValue_1 = v
  end

  if AppIdValue_1 == nil then
    commonFunctions:printError("ERROR: Value in DB for app: "..tostring(config.application1.registerAppInterfaceParams.fullAppID).."is unexpected value nil")
    is_test_fail = true
  else
    -- default group
    if(AppIdValue_1 ~= "686787169") then
      commonFunctions:printError("ERROR: Application: "..tostring(config.application1.registerAppInterfaceParams.fullAppID).."is not assigned to default group(686787169). Real: "..AppIdValue_1)
      is_test_fail = true
    end
  end

  query = " select functional_group_id from app_group where application_id = 'MyTestApp' "
  local AppIdValue_2
  local AppId_2 = commonFunctions:get_data_policy_sql(PolicyDBPath, query)
  for _,v in pairs(AppId_2) do
    AppIdValue_2 = v
  end

  if AppIdValue_2 == nil then
    commonFunctions:printError("ERROR: Value in DB for app: MyTestApp is unexpected value nil")
    is_test_fail = true
  else
    -- default group
    if(AppIdValue_2 ~= "686787169") then
      commonFunctions:printError("ERROR: Application: MyTestApp is not assigned to default group(686787169). Real: "..AppIdValue_2)
      is_test_fail = true
    end
  end
  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
