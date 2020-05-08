-- Requirement summary:
-- [PolicyTableUpdate] New application has registered and doesn't yet exist in Local PT during PTU in progress
--
-- Note: Copy attached ptu.json on this way: /tmp/fs/mp/images/ivsu_cache/
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
-- 1. PoliciesManager validates the updated PT (policyFile) e.i. verifyes, saves the updated fields and everything that is defined with related requirements)
-- 2. On validation success: SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- 3. SDL replaces the following sections of the Local Policy Table with the corresponding sections from PTU: module_config, functional_groupings, app_policies
-- 4. app_2 added to Local PT during PT Exchange process left after merge in LocalPT (not being lost on merge)
-- 5. SDL creates the new snapshot and initiates the new PTU for the app_2 Policies obtaining: SDL-> HMI: SDL.PolicyUpdate()//new PTU sequence started
-------------------------------------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

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
  appHMIType = {"COMMUNICATION"},
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
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          appID = self.applications [config.application1.registerAppInterfaceParams.appName],
          fileName = "sdl_snapshot.json"
        })
    end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
end

function Test:Precondition_OpenNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup ("Test")
function Test:TestStep_RAI_NewSession()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:TestStep_FinishPTU_ForAppId1()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}, {status = "UPDATE_NEEDED"}):Times(2)
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local CorIdSystemRequest = self.mobileSession:SendRPC ("SystemRequest", { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate", appID = config.application1.registerAppInterfaceParams.fullAppID },
  "files/jsons/Policies/Policy_Table_Update/ptu_without_preloaded.json")

  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
    end)
  EXPECT_RESPONSE(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
  :Do(function(_,_)
      self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
        {
          policyfile = SystemFilesPath.."/PolicyTableUpdate"
        })
    end)
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
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data3)
      self.hmiConnection:SendResponse(data3.id, data3.method, "SUCCESS", {})
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"})
end

function Test:TestStep_Start_New_PolicyUpdate_For_SecondApplication()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "filename"
        }
      )
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
        {
          fileName = "PolicyTableUpdate",
          requestType = "PROPRIETARY"
        }, "files/ptu_general.json")
      local systemRequestId
      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_,data)
          systemRequestId = data.id
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
            {
              policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
            })
          local function to_run()
            self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
          end
          RUN_AFTER(to_run, 800)
          self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
