---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] Assign existing policies to the application which appID exists in LocalPT
--
-- Description:
-- In case the application registers (sends RegisterAppInterface request) with the appID that exists in Local Policy Table,
-- PoliciesManager must apply the existing in "<appID>" from "app_policies" section of Local PT permissions to this application.
--
-- Preconditions:
-- 1. Register new "0000001" app
-- 2. Activate "0000001" app and device
-- 3. Start PTU with specific permissions for "123_xyz" app, which is not registered yet
-- 3. LPT is updated -> there are specific permissions for "123_xyz" app
-- Steps:
-- 1. Register new "123_xyz" app
-- 2. Catch OnPermissionsChange() notification and verify permissions in payload
--
-- Expected result:
-- Permissions in payload of OnPermissionsChange() notification is the same as defined in LPT (specific)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local policy_file_name = "PolicyTableUpdate"
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local ptu_file = "files/jsons/Policies/appID_Management/ptu_19849.json"
local r_expected = { "OnPermissionsChange", "RegisterAppInterface"}
local r_actual = { }

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
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")
config.application2.registerAppInterfaceParams.fullAppID = "123_xyz"

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ActivateApp()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"] })
  EXPECT_HMIRESPONSE(requestId1)
  :Do(function(_, data1)
  if data1.result.isSDLAllowed ~= true then
    local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
    { language = "EN-US", messageCodes = { "DataConsent" } })
    EXPECT_HMIRESPONSE(requestId2)
    :Do(function(_, _)
    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
    EXPECT_HMICALL("BasicCommunication.ActivateApp")
    :Do(function(_, data2)
    self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
    end)
    :Times(1)
    end)
  end
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep1_PTU()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })
  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
  :Do(function(_, _)
  local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file)
  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Do(function(_, data)
  self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
  self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
  end)
  EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
  :Do(function(_, _)
  requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusUpToDate" } })
  EXPECT_HMIRESPONSE(requestId)
  end)
  end)
  end)
end

function Test:TestStep2_StartNewSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:TestStep3_RegisterOnPermissionsChangeNotification()
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
  :Do(function(_, d)
  for _, v in pairs(d.payload.permissionItem) do
    table.insert(r_actual, v.rpcName)
  end
  end)
  :Times(AnyNumber())
  :Pin()
end

function Test:TestStep4_RegisterNewApp()
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
end

function Test:TestStep5_ValidateResult()
  if not is_table_equal(r_expected, r_actual) then
    self:FailTestCase("\nExpected RPCs:\n" .. commonFunctions:convertTableToString(r_expected, 1)
      .. "\nActual RPCs:\n" .. commonFunctions:convertTableToString(r_actual, 1))
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.StopSDL()
  StopSDL()
end
