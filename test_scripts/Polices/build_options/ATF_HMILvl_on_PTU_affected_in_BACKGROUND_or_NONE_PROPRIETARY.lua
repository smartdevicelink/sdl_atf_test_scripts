---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] HMILevel on Policy Update for the apps affected in NONE/BACKGROUND
--
-- Description:
-- SDL must change HMILevel of applications that are currently in NONE or BACKGROUND "default_hmi" from assigned policies in case of Policy Table Update
-- 1. Used preconditions
-- a) SDL is built with "DEXTENDED_POLICY: ON" flag, SDL and HMI are running
-- b) device is connected to SDL and is consented by the User
-- c) the app_1 is registered with SDL and is in BACKGROUND HMILevel
-- d) the app_2 is registered with SDL and is in NONE HMILevel
-- e) appID_1 and appID_2 have just received the updated PT with new permissions.
--
-- 2. Performed steps
-- 1) SDL->app_1: OnPermissionsChange
-- 2) SDL->app_2: OnPermissionsChange
--
-- Expected:
-- 1) SDL->appID_2: OnHMIStatus(BACKGROUND) //as "default_hmi" from the newly assigned policies has value of BACKGROUND

---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForBuildingSDLPolicyFlag = require('user_modules/shared_testcases/testCasesForBuildingSDLPolicyFlag')

--[[ Local Variables ]]
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local policy_file_name = "PolicyTableUpdate"
local ptu_file_1 = "files/jsons/Policies/build_options/ptu_18668_1.json"
local ptu_file_2 = "files/jsons/Policies/build_options/ptu_18668_2.json"
local sequence = { }
local r_actual_hmi_levels = { }
local r_actual_OnPermissionsChange = { }

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

local function get_app_hmi_id(self, id)
  return self.applications["App_" .. id]
end

local function register_default_app(self, id)
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :Do(function(_, d)
      self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
      self.applications = { }
      for _, app in pairs(d.params.applications) do
        self.applications[app.appName] = app.appID
      end
    end)
  local corId = self["mobileSession" .. id]:SendRPC("RegisterAppInterface", config["application" .. id].registerAppInterfaceParams)
  self["mobileSession" .. id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

local function start_mobile_session(self, id)
  self["mobileSession" .. id] = mobileSession.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. id]:StartService(7)
end

local function activate_app(self, id)
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = get_app_hmi_id(self, id) })
  EXPECT_HMIRESPONSE(requestId1)
end

local function deactivate_app(self, id)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", { appID = get_app_hmi_id(self, id)})
end

local function register_OnHMIStatus(self, id)
  self["mobileSession" .. id]:ExpectNotification("OnHMIStatus")
  :Do(function(_, d)
      log("SDL->MOB" .. id .. ": OnHMIStatus()", d.payload.hmiLevel)
      r_actual_hmi_levels[id] = d.payload.hmiLevel
    end)
  :Times(AnyNumber())
  :Pin()
end

local function register_OnPermissionsChange(self, id)
  self["mobileSession" .. id]:ExpectNotification("OnPermissionsChange")
  :Do(function(_, d)
      log("SDL->MOB" .. id .. ": OnPermissionsChange()", d.payload.requestType)
      r_actual_OnPermissionsChange[id] = true
    end)
  :Times(AnyNumber())
  :Pin()
end

local function ptu(self, id, ptu_file)
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name, appID = get_app_hmi_id(self, id) })
      self["mobileSession" .. id]:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, _)
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file)
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_, data)
              self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
            end)
          EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
          :Do(function(_, _)
              requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = { "StatusUpToDate" }})
              EXPECT_HMIRESPONSE(requestId)
            end)
        end)
    end)
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

--[[ General Precondition before ATF start ]]
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("PROPRIETARY")
commonFunctions:SDLForceStop()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

for i = 1, 2 do
  config["application" .. i].registerAppInterfaceParams.appName = "App_" .. i
end
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.Precondition_Clean()
  commonSteps:DeleteLogsFileAndPolicyTable()
  os.remove(config.pathToSDL .. "/app_info.dat") -- in order to skip resumption
  os.remove(policy_file_path .. "/sdl_snapshot.json")
  if not check_file_exists(policy_file_path .. "/sdl_snapshot.json") then
    print("PTS is removed")
  end
end

function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_initHMI()
  self:initHMI()
end

function Test:Precondition_initHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile()
  self:connectMobile()
end

function Test:StartMobileSession_1()
  start_mobile_session(self, 1)
end

function Test:StartMobileSession_2()
  start_mobile_session(self, 2)
end

function Test:Register_OnHMIStatus()
  register_OnHMIStatus(self, 1)
  register_OnHMIStatus(self, 2)
end

function Test:RegisterApp_1()
  register_default_app(self, 1)
end

function Test:RegisterApp_2()
  register_default_app(self, 2)
end

function Test:ActivateApp_1()
  activate_app(self, 1) -- app1 -> FULL
end

function Test:DeactivateApp_1() -- app1 -> BACKGROUND
  deactivate_app(self, 1)
end

function Test:Register_OnPermissionsChange()
  register_OnPermissionsChange(self, 1)
  register_OnPermissionsChange(self, 2)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Test_PTU_1()
  ptu(self, 1, ptu_file_1)
end

function Test:Test_UPDATING()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  EXPECT_HMIRESPONSE(reqId, {status = "UPDATING"})
end

function Test:Test_PTU_2()
  ptu(self, 2, ptu_file_2)
end

function Test:Test_UP_TO_DATE()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  EXPECT_HMIRESPONSE(reqId, {status = "UP_TO_DATE"})
end

function Test.Test_ShowSequence()
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

function Test:Test_Validation_OnHMIStatus()
  local r_expected_hmi_levels = { "BACKGROUND", "BACKGROUND" }
  for i = 1, 2 do
    if r_expected_hmi_levels[i] ~= r_actual_hmi_levels[i] then
      local msg = table.concat({
          "\nExpected OnHMIStatus() level for app '", i, "' is '", r_expected_hmi_levels[i],
          "', but actual is '", r_actual_hmi_levels[i], "'"})
      self:FailTestCase(msg)
    end
  end
end

function Test:Test_Validation_OnPermissionsChange()
  local r_expected_OnPermissionsChange = { true, true }
  for i = 1, 2 do
    if r_expected_OnPermissionsChange[i] ~= r_actual_OnPermissionsChange[i] then
      local msg = table.concat({"\nExpected OnPermissionsChange() notification for app '", i, "' was not sent"})
      self:FailTestCase(msg)
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
