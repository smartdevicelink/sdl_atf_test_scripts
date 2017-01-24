---------------------------------------------------------------------------------------------
-- PROPRIETARY flow
-- Requirement summary:
-- [PolicyTableUpdate] Apply PTU changes and OnPermissionChange notifying the apps
--
-- Description:
-- Right after the PoliciesManager merges the UpdatedPT with Local PT, it must apply the changes
-- and send onPermissionChange() notification to any registered mobile app in case the Updated PT
-- affected to this app`s policies.
-- a. SDL is built with "DEXTENDED_POLICY: ON" flag, SDL and HMI are running
-- b. AppID_1 is connected to SDL.
-- c. The device the app is running on is consented, appID1 requires PTU
-- d. Policy Table Update procedure is on stage waiting for:
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
-- e. 'policyfile' corresponds to PTU validation rules

-- Action:
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)

-- Expected:
-- 1. PoliciesManager validates the updated PT (policyFile) e.i. verifyes, saves the updated fields
-- and everything that is defined with related requirements)
-- 2. On validation success:
-- SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- 3. SDL replaces the following sections of the Local Policy Table with the corresponding sections from PTU:
-- module_config,
-- functional_groupings,
-- app_policies
-- 4. SDL removes 'policyfile' from the directory
-- 5. SDL->appID_1: onPermissionChange(permisssions)
-- 6. SDL->HMI: SDL.OnAppPermissionChanged(appID_1, permissions)
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local json = require("modules/json")
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForBuildingSDLPolicyFlag = require('user_modules/shared_testcases/testCasesForBuildingSDLPolicyFlag')

--[[ Local Variables ]]
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local policy_file_name = "PolicyTableUpdate"
local ptu_file = "files/jsons/Policies/build_options/ptu_18592.json"
local sequence = { }
local r_actual = { }

--[[ Local Functions ]]
local function timestamp()
  local f = io.popen("date +%H:%M:%S.%3N")
  local o = f:read("*all")
  f:close()
  return (o:gsub("\n", ""))
end

local function log(event, ...)
  table.insert(sequence, { ts = timestamp(), e = event, p = {...} })
end

local function check_file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

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
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("EXTERNAL_PROPRIETARY")
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Specific Notifications ]]
EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, d)
    log("SDL->HMI: SDL.OnStatusUpdate()", d.params.status)
    if d.params.status == "UP_TO_DATE" then
      table.insert(r_actual, "SDL.OnStatusUpdate(UP_TO_DATE)")
    end
  end)
:Times(AnyNumber())
:Pin()

EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
:Do(function(_, _)
    log("SDL->HMI: BC.PolicyUpdate()")
  end)
:Times(AnyNumber())
:Pin()

EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
:Do(function(_, _)
    log("SDL->HMI: BC.OnAppRegistered()")
  end)
:Times(AnyNumber())
:Pin()

EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged")
:Do(function(_, _)
    log("SDL->HMI: SDL.OnAppPermissionChanged()")
    table.insert(r_actual, "SDL.OnAppPermissionChanged")
  end)
:Times(AnyNumber())
:Pin()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test.CleanData()
  os.remove(policy_file_path .. "/sdl_snapshot.json")
  if not check_file_exists(policy_file_path .. "/sdl_snapshot.json") then
    print("PTS is removed")
  end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RegisterEvents()
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Do(function(_, _)
      log("SDL->MOB: OnPermissionsChange()")
      table.insert(r_actual, "OnPermissionsChange")
    end)
  :Times(AnyNumber())
  :Pin()
end

function Test:PTU()
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  log("HMI->SDL: SDL.GetURLS")
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      log("SDL->HMI: SDL.GetURLS")
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name})
      log("HMI->SDL: BC.OnSystemRequest")
      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function(_, _)
          log("SDL->MOB: OnSystemRequest")
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name}, ptu_file)
          log("MOB->SDL: SystemRequest")
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_, data)
              log("SDL->HMI: BC.SystemRequest")
              self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
              log("HMI->SDL: BC.SystemRequest")
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", {policyfile = policy_file_path .. "/" .. policy_file_name})
              log("HMI->SDL: SDL.OnReceivedPolicyUpdate")
            end)
          EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          :Do(function(_, _)
              log("SDL->MOB: SystemRequest")
              requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
              log("HMI->SDL: SDL.GetUserFriendlyMessage")
              EXPECT_HMIRESPONSE(requestId)
              log("SDL->HMI: SDL.GetUserFriendlyMessage")
            end)
        end)
    end)
end

function Test.ShowSequence()
  print("--- Sequence -------------------------------------")
  for k, v in pairs(sequence) do
    local s = k .. ": " .. v.ts .. ": " .. v.e
    for _, val in pairs(v.p) do
      if val then s = s .. ": " .. val end
    end
    print(s)
  end
  print("--------------------------------------------------")
end

function Test:ValidateSnapshot()
  if check_file_exists(policy_file_path .. "/sdl_snapshot.json") then
    self:FailTestCase("PTS is NOT removed")
  end
end

function Test:StartNewMobileSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RegisterNewApp()
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

function Test:Validate_OnStatusUpdate()
  local exp = "SDL.OnStatusUpdate(UP_TO_DATE)"
  if r_actual[1] ~= exp then
    self:FailTestCase(table.concat({"\nExpected notification ", exp, " was not sent"}))
  end
end

function Test:Validate_OnPermissionsChange()
  local exp = "OnPermissionsChange"
  if r_actual[2] ~= exp then
    self:FailTestCase(table.concat({"\nExpected notification ", exp, " was not sent"}))
  end
end

function Test:Validate_OnAppPermissionChanged()
  local exp = "SDL.OnAppPermissionChanged"
  if r_actual[3] ~= exp then
    self:FailTestCase(table.concat({"\nExpected notification ", exp, " was not sent"}))
  end
end

function Test:Validate_PTS()
  local pts = json_to_table(policy_file_path .. "/sdl_snapshot.json") -- actual
  local ptu = json_to_table(ptu_file) -- expected
  -- Reconcile expected vs actual
  ptu.policy_table.module_config.preloaded_pt = false
  pts.policy_table.app_policies["0000001"].certificate = nil

  -- Compare
  if not is_table_equal(ptu.policy_table.functional_groupings, pts.policy_table.functional_groupings) then
    self:FailTestCase("Diffs in 'functional_groupings' section\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.functional_groupings, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.functional_groupings, 1))
  end
  if not is_table_equal(ptu.policy_table.module_config, pts.policy_table.module_config) then
    self:FailTestCase("Diffs in 'module_config' section\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.module_config, 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.module_config, 1))
  end
  -- Section app_policies verified for '0000001' app only
  if not is_table_equal(ptu.policy_table.app_policies["0000001"], pts.policy_table.app_policies["0000001"]) then
    self:FailTestCase("Diffs in 'app_policies' section\nExpected:\n" .. commonFunctions:convertTableToString(ptu.policy_table.app_policies["0000001"], 1) .. "\nActual:\n" .. commonFunctions:convertTableToString(pts.policy_table.app_policies["0000001"], 1))
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.StopSDL()
  StopSDL()
end

return Test
