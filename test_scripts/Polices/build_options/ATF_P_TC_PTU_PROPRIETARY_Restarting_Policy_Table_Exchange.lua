---------------------------------------------------------------------------------------------
-- PROPRIETARY flow
-- Requirement summary:
-- [PolicyTableUpdate] Restarting Policy Table Exchange
--
-- Description:
-- Policy Manager must restart retry sequence within the same ignition cycle
-- only if anything triggers Policy Table Update request.
--
-- Preconditions
-- 1. Update LPT by shorten retry cycle
-- 2. LPT is updated -> SDL.OnStatusUpdate(UP_TO_DATE)
-- Steps:
-- 1. Register new app_1 -> PTU sequence started
-- 2. PTU retry sequence failed
-- 3. PTU retry sequence finished -> last status of SDL.OnStatusUpdate(UPDATE_NEEDED)
-- 5. Register new app_2 -> PTU sequence started
-- 6. Verify first status of SDL.OnStatusUpdate()
-- 7. Verify that PTS is created
-- 8. Verify that OnSystemRequest() notification is sent
--
-- Expected result:
-- 6. Status: UPDATE_NEEDED
-- 7. PTS is created
-- 8. OnSystemRequest() notification is sent to MOB
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
local ptu_file = "files/jsons/Policies/build_options/ptu_18551.json"
local sequence = { }
local attempts_1 = 10
local attempts_2 = 10
local r_expected_1_status = "UPDATE_NEEDED"
local r_expected_2_status = "UPDATE_NEEDED"
local r_expected_2_type = "PROPRIETARY"
local r_actual_sequence = { }
local r_actual_1_status
local r_actual_2_status
local r_actual_2_type = { }

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

local function contains(t, item)
  for _, v in pairs(t) do
    if v == item then return true end
  end
  return false
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

--[[ General Precondition before ATF start ]]
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("PROPRIETARY")
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")
config.defaultProtocolVersion = 2

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Update_LPT()
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
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
              requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusUpToDate" }})
              EXPECT_HMIRESPONSE(requestId)
            end)
        end)
    end)
end

-- --[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:StartNewMobileSession_2()
  start_mobile_session(self, 2)
end

function Test:RegisterEvents()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :Do(function(_, d)
      log("SDL->HMI: SDL.OnStatusUpdate()", d.params.status)
      table.insert(r_actual_sequence, d.params.status)
    end)
  :Times(AnyNumber())
  :Pin()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, _)
      log("SDL->HMI: BC.PolicyUpdate()")
    end)
  :Times(AnyNumber())
  :Pin()
  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(function(_, d)
      log("SDL->MOB: OnSystemRequest()", d.payload.requestType)
      table.insert(r_actual_2_type, d.payload.requestType)
    end)
  :Times(AnyNumber())
  :Pin()
  self.mobileSession2:ExpectNotification("OnSystemRequest")
  :Do(function(_, d)
      log("SDL->MOB2: OnSystemRequest()", d.payload.requestType)
      table.insert(r_actual_2_type, d.payload.requestType)
    end)
  :Times(AnyNumber())
  :Pin()
end

function Test:RegisterNewApp_2()
  register_default_app(self, 2)
end

function Test:PTU_2()
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })
    end)
end

Test["Starting waiting cycle [" .. attempts_1 * 5 .. "] sec"] = function() end

for i = 1, attempts_1 do
  Test["Waiting " .. i * 5 .. " sec"] = function()
    os.execute("sleep 5")
  end
end

function Test.FinishCycle_1()
  r_actual_1_status = r_actual_sequence[#r_actual_sequence]
  log("--- 1st retry cycle finished ---")
  r_actual_sequence = { }
  r_actual_2_type = { }
end

function Test.CleanData()
  os.remove(policy_file_path .. "/sdl_snapshot.json")
  if not check_file_exists(policy_file_path .. "/sdl_snapshot.json") then
    print("PTS is removed")
  end
end

function Test:StartNewMobileSession_3()
  start_mobile_session(self, 3)
end

function Test:RegisterEvents()
  self.mobileSession3:ExpectNotification("OnSystemRequest")
  :Do(function(_, d)
      log("SDL->MOB3: OnSystemRequest()", d.payload.requestType, d.payload.url)
      table.insert(r_actual_2_type, d.payload.requestType)
    end)
  :Times(AnyNumber())
  :Pin()
end

function Test:RegisterNewApp_3()
  register_default_app(self, 3)
end

Test["Starting waiting cycle [" .. attempts_2 * 5 .. "] sec"] = function() end

for i = 1, attempts_2 do
  Test["Waiting " .. i * 5 .. " sec"] = function()
    os.execute("sleep 5")
  end
end

function Test.FinishCycle_2()
  r_actual_2_status = r_actual_sequence[1]
  log("--- 2nd retry cycle finished ---")
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

function Test:ValidateOnStatusUpdate()
  if r_expected_1_status ~= r_actual_1_status then
    self:FailTestCase("\nFor the 1st retry cycle last status of OnStatusUpdate()\nExpected: " .. r_expected_1_status .. "\nActual: " .. tostring(r_actual_1_status))
  end
  if r_expected_2_status ~= r_actual_2_status then
    self:FailTestCase("\nFor the 2nd retry cycle first status of OnStatusUpdate()\nExpected: " .. r_expected_2_status .. "\nActual: " .. tostring(r_actual_2_status))
  end
end

function Test:ValidateSnapshot()
  if not check_file_exists(policy_file_path .. "/sdl_snapshot.json") then
    self:FailTestCase("PTS is NOT created during 2nd retry cycle")
  end
end

function Test:ValidateOnSystemRequest()
  if not contains(r_actual_2_type, r_expected_2_type) then
    self:FailTestCase("\nFor the 2nd retry cycle OnSystemRequest() with expected type '" .. r_expected_2_type .. "' was not sent")
  end
end

return Test
