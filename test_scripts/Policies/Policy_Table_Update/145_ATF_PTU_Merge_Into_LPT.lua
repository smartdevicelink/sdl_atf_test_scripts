---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] PTU merge into Local Policy Table
--
-- Description:
-- On successful validation of PTU, SDL must replace the following sections of the Local Policy Table with the corresponding sections from PTU:
-- - module_config,
-- - functional_groupings,
-- - app_policies
--
-- Preconditions
-- 1. LPT has non empty 'module_config', 'functional_groupings', 'app_policies' sections
-- 2. Register new app
-- 3. Activate app
-- Steps:
-- 1. Perform PTU with specific data in 'module_config', 'functional_groupings', 'app_policies' sections
-- 2. After PTU is finished verify data in mentioned sections
--
-- Expected result:
-- Previous version of sections in LPT are replaced by a new ones
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local json = require("modules/json")
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local policy_file_name = "PolicyTableUpdate"
local ptu_file = "files/jsons/Policies/Policy_Table_Update/ptu_18190.json"
local pts_file_with_full_app_id_supported = "files/jsons/Policies/Policy_Table_Update/ptu_file_with_full_app_id_supported.json"
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

local function update_preloaded_pt_removeRC()
  local config_path = commonPreconditions:GetPathToSDL()

  local pathToFile = config_path .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all")
  file:close()

  local data = json.decode(json_data)
  if(data.policy_table.functional_groupings["DataConsent-2"]) then
    data.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  end

  --RC data
  data.policy_table.module_config.equipment = nil
  data.policy_table.module_config.country_consent_passengersRC = nil

  file = io.open(config_path .. 'sdl_preloaded_pt.json', "w")
  file:write(json.encode(data))
  file:close()
end

--[[ General Precondition before ATF start ]]
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
update_preloaded_pt_removeRC()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_ActivateApp()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU()

  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })

  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name})

      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function(_, _)
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name},
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

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
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

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function Test:TestStep_ValidateResult()
  local pts = json_to_table(policy_file_path .. "/sdl_snapshot.json")
  local ptu = json_to_table(pts_file_with_full_app_id_supported)
  -- Reconcile expected vs actual
  ptu.policy_table.module_config.preloaded_pt = false
  ptu.policy_table.app_policies["0000002"] = "default"
  -- Compare
  if not is_table_equal(ptu.policy_table.functional_groupings, pts.policy_table.functional_groupings) then
    self:FailTestCase("Diffs in functional_groupings\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.functional_groupings, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.functional_groupings, 1))
  end
  if not is_table_equal(ptu.policy_table.module_config, pts.policy_table.module_config) then
    self:FailTestCase("Diffs in module_config\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.module_config, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.module_config, 1))
  end
  -- Section app_policies verified for '0000001' app only
  if not is_table_equal(ptu.policy_table.app_policies["0000001"], pts.policy_table.app_policies["0000001"]) then
    self:FailTestCase("Diffs in app_policies\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.app_policies["0000001"], 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.app_policies["0000001"], 1))
  end
  -- Section app_policies verified for '0000002' app only
  if not is_table_equal(ptu.policy_table.app_policies["0000002"], pts.policy_table.app_policies["0000002"]) then
    self:FailTestCase("Diffs in app_policies\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.app_policies["0000002"], 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.app_policies["0000002"], 1))
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_files()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
