---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "pre_DataConsent" policies assigned to the application and "priority" value
--
-- Description:
-- Providing to HMI app`s default priority value of "pre_DataConsent" if "pre_DataConsent" policies assigned to the application
-- 1. Used preconditions:
-- SDL and HMI are running
-- Close default connection
-- Connect device
--
-- 2. Performed steps
-- Register app-> "pre_DataConsent" policies are assigned to the application
-- Activate app
--
-- Expected result:
-- PoliciesManager must not provide to HMI the app`s priority value
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_connect_device.lua")
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_connect_device')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()

function Test:Precondition_Close_default_connection()
  self.mobileConnection:Close()
  commonTestCases:DelayedExp(3000)
end

function Test:Precondition_Connect_device()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
 if utils.getDeviceTransportType() == "WIFI" then
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep1_Priority_NONE_OnAppRegistered()
  commonTestCases:DelayedExp(3000)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {priority = nil })
      :Do(function(_,data)
          self.HMIAppID = data.params.application.appID
        end)
      self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
end

function Test:TestStep2_Priority_NONE_ActivateApp()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId, {result = { code = 0, method ="SDL.ActivateApp", priority = nil }})
  :Do(function(_,data)
      if data.result.priority ~= nil then
        commonFunctions:userPrint(31, "Error: wrong behavior of SDL - priority should be omitted")
      end
      EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)
      EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
    end)
end

function Test:Precondition_Check_priority_pre_DataConsent()
  local app_group_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select functional_group_id from app_group where application_id = '"..config.application1.registerAppInterfaceParams.fullAppID.."'")
  local app_group
  for _,value in pairs(app_group_table) do
    app_group = value
  end

  -- 129372391 - BaseBeforeDataConsent
  if(app_group ~= "129372391") then
    self:FailTestCase("Application is not assigned to pre_DataConsent. Real: "..app_group)
  end

  local priority_id_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select priority_value from application where id = '"..config.application1.registerAppInterfaceParams.fullAppID.."'")
  local priority_id
  for _, value in pairs(priority_id_table) do
    priority_id = value
  end

  if(priority_id ~= "NONE") then
    self:FailTestCase("Priority for pre_DataConsent is not NONE. Real: "..priority_id)
  end

  local is_predata_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select is_predata from application where id = '"..config.application1.registerAppInterfaceParams.fullAppID.."'")
  local is_predata
  for _,value in pairs(is_predata_table) do
    is_predata = value
  end

  if(is_predata ~= "1") then
    self:FailTestCase("Application is not assigned to pre_DataConsent, is_predata = "..priority_id)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()

function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
