-- Requirements summary:
-- [PolicyTableUpdate] PTU merge into Local Policy Table
-- [HMI API] OnStatusUpdate
--
-- Description:
-- On successful validation of PTU, SDL must replace the following sections of the
-- Local Policy Table with the corresponding sections from PTU:
-- module_config, functional_groupings and app_policies
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- PTU to be received satisfies data dictionary requirements and its
-- 'consumer_friendly_messages' section doesn't contain a 'messages' subsection
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:HTTP)
-- SDL->app: OnSystemRequest ('url', requestType:HTTP, fileType="JSON")
-- app->SDL: SystemRequest(requestType=HTTP)
-- SDL->HMI: SystemRequest(requestType=HTTP, fileName)
-- HMI->SDL: SystemRequest(SUCCESS)
-- 2. Performed steps
-- HMI->SDL: OnReceivedPolicyUpdate(policy_file) according to data dictionary
-- SDL->HMI: OnStatusUpdate(UP_TO_DATE)
-- Expected result:
-- SDL replaces the following sections of the Local Policy Table with the
--corresponding sections from PTU: module_config, functional_groupings and app_policies
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Required Shared libraries ]]
local json = require("modules/json")
local mobileSession = require("mobile_session")
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require ('user_modules/utils')

--[[ Local Functions ]]
local function is_table_equal(t1, t2)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not is_table_equal(v1, v2) then return false end
  end
  for k2, v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not is_table_equal(v1, v2) then return false end
  end
  return true
end

--[[ General Precondition before ATF start ]]
testCasesForPolicyTable.Delete_Policy_table_snapshot()
commonSteps:DeleteLogsFileAndPolicyTable()
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')
local ptu

--[[Preconditions]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_ConnectDevice()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  if utils.getDeviceTransportType() == "WIFI" then
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

function Test:Precondition_RegisterApp()
  commonTestCases:DelayedExp(3000)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID = data.params.application.appID
        end)
      self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)

  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do( function(_, data)
      print("SDL -> MOB1: OnSystemRequest, requestType: "..data.payload.requestType)
      if(data.payload.requestType == "HTTP") then
        ptu = json.decode(data.binaryData)
      end
    end)
  :Times(2)

end

function Test:Precondition_ActivateApp()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID})
  EXPECT_HMIRESPONSE(RequestId)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU()
  commonFunctions:check_ptu_sequence_partly(self, "files/jsons/Policies/Policy_Table_Update/ptu_without_preloaded.json", "PolicyTableUpdate")
end

function Test:TestStep_StartNewMobileSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:TestStep_RegisterNewApp()
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :Do(function(_, d)
      self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
      self.applications = { }
      for _, app in pairs(d.params.applications) do
        self.applications[app.appName] = app.appID
      end
    end)
  :Times(Between(1,2))

  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)

  self.mobileSession2:ExpectNotification("OnSystemRequest", {requestType = "LOCK_SCREEN_ICON_URL"})
  :Do(function(_,data)
      print("SDL -> MOB2: OnSystemRequest, requestType: "..data.payload.requestType)
    end)

  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do( function(_, data)
      print("SDL -> MOB1: OnSystemRequest, requestType: "..data.payload.requestType)
      if(data.payload.requestType == "HTTP") then
        if(data.binaryData ~= nil and data.binaryData ~= "" ) then
          ptu = json.decode(data.binaryData)
        else
          self:FailTestCase("Binary data is empty")
        end
      else
        self:FailTestCase("OnSystemRequest, HTTP for app1 is not received.")
      end
    end)

  commonTestCases:DelayedExp(10000)
end

function Test:TestStep_ValidateResult()
  if (ptu == nil) then
    self:FailTestCase("Binary Data are empty")
  else
    local is_test_fail = false
    -- Reconcile expected vs actual
    ptu.policy_table.module_config.preloaded_pt = false
    ptu.policy_table.app_policies["0000002"] = "default"

    -- Compare
    if not is_table_equal(ptu.policy_table.functional_groupings, ptu.policy_table.functional_groupings) then
      commonFunctions:printError("Diffs in functional_groupings\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.functional_groupings, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(ptu.policy_table.functional_groupings, 1) )
      is_test_fail = false
    end
    if not is_table_equal(ptu.policy_table.module_config, ptu.policy_table.module_config) then
      commonFunctions:printError("Diffs in module_config\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.module_config, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(ptu.policy_table.module_config, 1) )
      is_test_fail = false
    end
    -- Section app_policies verified for '0000001' app only
    if not is_table_equal(ptu.policy_table.app_policies["0000001"], ptu.policy_table.app_policies["0000001"]) then
      commonFunctions:printError("Diffs in app_policies\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.app_policies["0000001"], 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(ptu.policy_table.app_policies["0000001"], 1) )
      is_test_fail = false
    end
    -- Section app_policies verified for '0000002' app only
    if not is_table_equal(ptu.policy_table.app_policies["0000002"], ptu.policy_table.app_policies["0000002"]) then
      commonFunctions:printError("Diffs in app_policies\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.app_policies["0000002"], 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(ptu.policy_table.app_policies["0000002"], 1) )
      is_test_fail = false
    end

    if(is_test_fail == true) then
      self:FailTestCase("Test is FAILED. See prints.")
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test

