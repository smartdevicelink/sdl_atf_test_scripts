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

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local json = require("modules/json")
local mobileSession = require("mobile_session")
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Local Variables ]]
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local policy_file_name = "PolicyTableUpdate"
local ptu_file = "files/jsons/Policies/Policy_Table_Update/ptu_18190.json"
--"files/ptu_general.json")
--[[ Local Functions ]]
local function json_to_table(file)
  local f = io.open(file, "r")
  if f == nil then error("File not found") end
  local ptString = f:read("*all")
  f:close()
  return json.decode(ptString)
end

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

--[[Preconditions]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_ConnectDevice()
  local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    {
      deviceList = {
        {
          id = config.deviceMAC,
          isSDLAllowed = true,
          name = ServerAddress,
          transportType = "WIFI"
        }
      }
    }
    ):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
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
end

function Test:Precondition_ActivateApp()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)
      self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
        {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
      EXPECT_HMICALL("BasicCommunication.ActivateApp")
      :Do(function(_,_data1)
          self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU()

  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {requestType = "HTTP", fileName = policy_file_name})

      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP"})
      :Do(function(_, _)
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "HTTP", fileName = policy_file_name},
            ptu_file)
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_, data)
              self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", {policyfile = policy_file_path .. "/" .. policy_file_name})
            end)
          EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          :Do(function(_,_)
              local requestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
              EXPECT_HMIRESPONSE(requestId1)
            end)
        end)
    end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    {status = "UPDATING"}, {status = "UP_TO_DATE"}):Times(2)
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
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function Test:TestStep_ValidateResult()
  self.mobileSession:ExpectAny()
  :ValidIf(function(_, _)
      local pts = json_to_table(policy_file_path .. "/sdl_snapshot.json")
      local ptu = json_to_table(ptu_file)
      -- Reconcile expected vs actual
      ptu.policy_table.module_config.preloaded_pt = false
      ptu.policy_table.app_policies["0000002"] = "default"

      -- Compare
      if not is_table_equal(ptu.policy_table.functional_groupings, pts.policy_table.functional_groupings) then
        return false, "Diffs in functional_groupings\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.functional_groupings, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.functional_groupings, 1)
      end
      if not is_table_equal(ptu.policy_table.module_config, pts.policy_table.module_config) then
        return false, "Diffs in module_config\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.module_config, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.module_config, 1)
      end
      -- Section app_policies verified for '0000001' app only
      if not is_table_equal(ptu.policy_table.app_policies["0000001"], pts.policy_table.app_policies["0000001"]) then
        return false, "Diffs in app_policies\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.app_policies["0000001"], 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.app_policies["0000001"], 1)
      end
      -- Section app_policies verified for '0000002' app only
      if not is_table_equal(ptu.policy_table.app_policies["0000002"], pts.policy_table.app_policies["0000002"]) then
        return false, "Diffs in app_policies\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.app_policies["0000002"], 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.app_policies["0000002"], 1)
      end
      return true
    end)
  :Times(1)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
