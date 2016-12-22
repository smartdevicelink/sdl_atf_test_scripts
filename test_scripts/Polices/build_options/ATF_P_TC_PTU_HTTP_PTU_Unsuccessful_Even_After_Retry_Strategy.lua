---------------------------------------------------------------------------------------------
-- HTTP flow
-- Requirement summary:
-- [PolicyTableUpdate] PTU unsuccessful even after Retry strategy - initiate PTU the next ignition cycle
--
-- Description:
-- In case the policy table exchange is unsuccessful after the retry strategy is completed,
-- the Policy Manager must initiate the new PT exchange sequence upon the next ignition on.
--
-- Preconditions
-- 1. Update LPT by shorten retry cycle
-- 2. LPT is updated -> SDL.OnStatusUpdate(UP_TO_DATE)
-- Steps:
-- 1. Register new app -> PTU sequence started
-- 2. PTU retry sequence failed -> last status of SDL.OnStatusUpdate(UPDATE_NEEDED)
-- 3. IGN_OFF
-- 4. IGN_ON
-- 5. Register app -> PTU sequence started
-- 6. Verify first status of SDL.OnStatusUpdate()
-- 7. Verify that PTS is created
--
-- Expected result:
-- 6. Status: UPDATE_NEEDED
-- 7. PTS is created
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")

--[[ Local Variables ]]
local system_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local ptu
local ptu_file = os.tmpname()
local sequence = { }
local attempts_1 = 10
local attempts_2 = 10
local r_expected_1_status = "UPDATE_NEEDED"
local r_expected_2_status = "UPDATE_NEEDED"
local r_actual_sequence = { }
local r_actual_1_status
local r_actual_2_status

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

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")
config.defaultProtocolVersion = 2

--[[ Specific Notifications ]]
function Test:RegisterNotification()
  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(function(_, d)
      ptu = json.decode(d.binaryData)
    end)
  :Times(AtLeast(1))
  :Pin()
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ValidatePTS()
  if ptu.policy_table.consumer_friendly_messages.messages then
    self:FailTestCase("Expected absence of 'consumer_friendly_messages.messages' section in PTS")
  end
end

function Test.UpdatePTS()
  ptu.policy_table.device_data = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.app_policies["0000001"] = { keep_context = false, steal_focus = false, priority = "NONE", default_hmi = "NONE" }
  ptu.policy_table.app_policies["0000001"]["groups"] = { "Base-4", "Base-6" }
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  -- set minimum values for timeouts of retry cycle
  ptu.policy_table.module_config.seconds_between_retries = { 1, 1 }
  ptu.policy_table.module_config.timeout_after_x_seconds = 10
end

function Test.StorePTSInFile()
  local f = io.open(ptu_file, "w")
  f:write(json.encode(ptu))
  f:close()
end

function Test:Update_LPT()
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = "PolicyTableUpdate" }, ptu_file)
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
end

-- --[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:StartNewMobileSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RegisterEvents()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :Do(function(_, d)
      log("SDL->HMI: SDL.OnStatusUpdate", d.params.status)
      table.insert(r_actual_sequence, d.params.status)
    end)
  :Times(AnyNumber())
  :Pin()
  self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "HTTP" })
  :Do(function()
      log("SDL->MOB1: OnSystemRequest")
    end)
  :Times(AnyNumber())
  :Pin()
  self.mobileSession2:ExpectNotification("OnSystemRequest", { requestType = "HTTP" })
  :Do(function()
      log("SDL->MOB2: OnSystemRequest")
    end)
  :Times(AnyNumber())
  :Pin()
end

function Test:RegisterApp_2()
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :Do(function(_, d)
      self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
      self.applications = { }
      for _, app in pairs(d.params.applications) do
        self.applications[app.appName] = app.appID
      end
    end)
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  log("MOB2->SDL: RegisterAppInterface")
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  log("SDL->MOB2: SUCCESS: RegisterAppInterface")
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
end

function Test:Ignition_Off()
  StopSDL()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(2)
end

function Test.CleanData()
  os.remove(config.pathToSDL .. "/app_info.dat") -- in order to skip resumption
  os.remove(system_file_path .. "/sdl_snapshot.json")
  if not check_file_exists(system_file_path .. "/sdl_snapshot.json") then
    print("PTS is removed")
  end
end

function Test:RunSDL()
  self:runSDL()
end

function Test:InitHMI()
  self:initHMI()
end

function Test:InitHMI_onReady()
  self:initHMI_onReady()
end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartMobileSession_1()
  self.mobileSession = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:StartMobileSession_2()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RegisterEvents()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :Do(function(_, d)
      log("SDL->HMI: SDL.OnStatusUpdate", d.params.status)
      table.insert(r_actual_sequence, d.params.status)
    end)
  :Times(AnyNumber())
  :Pin()
  self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "HTTP" })
  :Do(function()
      log("SDL->MOB1: OnSystemRequest")
    end)
  :Times(AnyNumber())
  :Pin()
  self.mobileSession2:ExpectNotification("OnSystemRequest", { requestType = "HTTP" })
  :Do(function()
      log("SDL->MOB2: OnSystemRequest")
    end)
  :Times(AnyNumber())
  :Pin()
end

function Test:RegisterApp_2()
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :Do(function(_, d)
      self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
      self.applications = { }
      for _, app in pairs(d.params.applications) do
        self.applications[app.appName] = app.appID
      end
    end)
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  log("MOB2->SDL: RegisterAppInterface")
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  log("SDL->MOB2: SUCCESS: RegisterAppInterface")
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

function Test:ValidateStatuses_1()
  if r_expected_1_status ~= r_actual_1_status then
    local msg = table.concat({"\nFor the 1st retry cycle last status of OnStatusUpdate()",
        "\nExpected: ", r_expected_1_status,
        "\nActual: ", tostring(r_actual_1_status)})
    self:FailTestCase(msg)
  end
end

function Test:ValidateStatuses_2()
  if r_expected_2_status ~= r_actual_2_status then
    local msg = table.concat({"\nFor the 2nd retry cycle first status of OnStatusUpdate()",
        "\nExpected: ", r_expected_2_status,
        "\nActual: ", tostring(r_actual_2_status)})
    self:FailTestCase(msg)
  end
end

function Test:ValidateSnapshot()
  if not check_file_exists(system_file_path .. "/sdl_snapshot.json") then
    self:FailTestCase("PTS is NOT created during 2nd retry cycle")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Clean()
  os.remove(ptu_file)
end

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
