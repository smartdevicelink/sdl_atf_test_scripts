---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] OnStatusUpdate trigger
-- [HMI API] OnStatusUpdate
--
-- Description:
-- PoliciesManager must notify HMI via SDL.OnStatusUpdate notification right after one of the statuses
-- of UPDATING, UPDATE_NEEDED and UP_TO_DATE is changed from one to another.
--
-- Steps:
-- 1. Register new app1
-- 2. SDL->HMI: Verify status of SDL.OnStatusUpdate notification
-- 3. Trigger PTU
-- 4. Register new app2
--
-- Expected result:
-- Status changes in a wollowing way:
-- "UPDATE_NEEDED" -> "UPDATING" -> "UP_TO_DATE" -> "UPDATE_NEEDED" -> "UPDATING"
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local utils = require ('user_modules/utils')

--[[ Local variables ]]
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
local policy_file_name = "PolicyTableUpdate"
local file = "files/jsons/Policies/Policy_Table_Update/ptu_18707_1.json"

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Trigger_Device_consent()
  local is_test_fail = false
  self.hmi_app1_id = self.applications[config.application1.registerAppInterfaceParams.appName]

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)

      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          testCasesForPolicyTable.time_trigger = timestamp()

          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})

          -- EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})

          EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = policy_file_path .. "sdl_snapshot.json"})
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            end)
        end)
    end)

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

function Test:TestStep_PTU_Success()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_,_)
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})

      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = policy_file_name})
      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function(_,_)

          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            {requestType = "PROPRIETARY", fileName = policy_file_name, appID = self.hmi_app1_id}, file)
          EXPECT_HMICALL("BasicCommunication.SystemRequest",{ requestType = "PROPRIETARY", fileName = policy_file_path..policy_file_name })
          :Do(function(_,_data1)
              self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. policy_file_name})
            end)
          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          :Do(function(_, _)
              local requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusUpToDate" } })
              EXPECT_HMIRESPONSE(requestId)
            end)
        end)
    end)
end

function Test:TestStep_StartNewSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:TestStep_RegisteNewApp()
  config.application2.registerAppInterfaceParams.appName = "App1"
  config.application2.registerAppInterfaceParams.fullAppID = "123_abc"

  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    { application = { appName = config.application2.registerAppInterfaceParams.appName }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
