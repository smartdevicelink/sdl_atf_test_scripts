------------- --------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: User-disallowed device after applications consent
--
-- Description:
-- User disallows device via Settings Menu after device and apps on device are consented
--
-- 1. Used preconditions:
-- Delete log files and policy table from previous ignition cycle
-- Activate app -> consent device
-- Disallow device via Settings Menu
-- 2.Performed steps:
-- Send RPC from default group
-- Allow device
-- Send RPC from default group again
--
-- Expected result:
-- App consents must remain the same, app must be rolled back to pre_DataConstented group -> RPC from defult should not be allowed
-- App must be rolled back to default group
-- RPC from defult should be allowed
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ Local variables ]]
local pre_dataconsent = "129372391"
local base4 = "686787169"

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Precondition ]]
function Test:Precondition_ActivateRegisteredApp()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:Precondition_Check_App_assigned_BASE4()
  local group_app_id_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "SELECT functional_group_id FROM app_group where application_id = '0000001'")

  local group_app_id
  for _, value in pairs(group_app_id_table) do
    group_app_id = value
  end
  if(group_app_id ~= base4) then
    self:FailTestCase("Application is not assigned to Base-4. Group: "..group_app_id)
  end
end

function Test:Precondition_Disallow_device()
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    {allowed = false, source = "GUI", device = {id = utils.getDeviceMAC() , name = utils.getDeviceName()}})
  EXPECT_NOTIFICATION("OnPermissionsChange")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep1_Check_App_assigned_PreDataConsent()
  local group_app_id_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "SELECT functional_group_id FROM app_group where application_id = '0000001'")

  local group_app_id
  for _, value in pairs(group_app_id_table) do
    group_app_id = value
  end
  if(group_app_id ~= pre_dataconsent) then
    self:FailTestCase("Application is not assigned to BaseBeforeDataConsent. Group: "..group_app_id)
  end
end

function Test:TestStep1_Send_RPC_from_default_disallowed()
  --AddCommand belongs to default permissions, so should be disallowed
  local RequestIDAddCommand = self.mobileSession:SendRPC("AddCommand", { cmdID = 111, menuParams = { position = 1, menuName ="Command111" } })
  EXPECT_HMICALL("UI.AddCommand",{})
  :Times(0)
  EXPECT_RESPONSE(RequestIDAddCommand, { success = false, resultCode = "DISALLOWED" })
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

function Test:ActivateApp()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName] })
  EXPECT_HMIRESPONSE(requestId1)
  :Do(function(_, data1)
      if data1.result.isSDLAllowed ~= true then
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(requestId2)
        :Do(function(_, _)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_, data2)
                self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
              end)
            :Times(1)
          end)
      end
    end)
end

function Test:TestStep3_Send_RPC_from_default_again()
  local RequestIDAddCommand = self.mobileSession:SendRPC("AddCommand", { cmdID = 111, menuParams = { position = 1, menuName ="Command111" } })
  EXPECT_HMICALL("UI.AddCommand",{})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(RequestIDAddCommand, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end

function Test:Precondition_Check_App_assigned_BASE4()
  local group_app_id_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "SELECT functional_group_id FROM app_group where application_id = '0000001'")

  local group_app_id
  for _, value in pairs(group_app_id_table) do
    group_app_id = value
  end
  if(group_app_id ~= base4) then
    self:FailTestCase("Application is not assigned to Base-4. Group: "..group_app_id)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
