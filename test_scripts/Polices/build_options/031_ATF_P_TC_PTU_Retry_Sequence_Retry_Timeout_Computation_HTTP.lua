---------------------------------------------------------------------------------------------
-- HTTP flow
-- Requirement summary:
-- [PolicyTableUpdate] Policy Table Update retry timeout computation
--
-- Description:
-- PoliciesManager must use the values from "seconds_between_retries" section of Local PT as the values to
-- computate the timeouts of retry sequense (that is, seconds to wait for the response).
--
-- 1. Used preconditions
-- Aplication with <appID_1> is running on SDL
-- PTU with updated 'timeout_after_x_seconds' and 'seconds_between_retries' params is performed to speed up the test
-- PTU finished successfully (UP_TO_DATE)
-- 2. Performed steps
-- Trigger new PTU by registering Application 2
-- SDL -> mobile OnSystemRequest (params, url)
-- PolicyTableUpdate won't come within futher defined 'timeout'
-- Check timestamps of BC.PolicyUpdate() requests
-- Calculate seconds_between_retries
--
-- Expected result: Retry sequence started:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED), PoliciesManager takes the timeouts for retry sequence from "seconds_between_retries" section of Local PT.
-- SDL->app ID: send SnapshotPT via OnSystemRequest
-- wait during timeout (e.g. 10s)
-- PTU not received
-- SDL->app ID: send SnapshotPT via OnSystemRequest
-- wait during t1 + timeout (e.g. 1s + 10s = 11s)
-- PTU not received
-- SDL->app ID: send SnapshotPT via OnSystemRequest
-- wait during t2 + t1 + timeout (e.g. 11s + 1s + 10s = 22s)
-- PTU not received
-- SDL->app ID: send SnapshotPT via OnSystemRequest
-- wait during t3 + t2 + timeout (e.g. 22s + 1s + 10s = 33s)
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")

--[[ Local Variables ]]
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local policy_file_name = "PolicyTableUpdate"
local f_name = os.tmpname()
local ptu
local sequence = { }
local accuracy = 5
local r_expected = { 11, 22, 33 }
local r_actual = { }
local attempts = 15
local timestamps = { }

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

local function show_log()
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

local function check_file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

local function get_min(v, a)
  if v - a < 0 then return 1 end
  return v - a
end

local function get_max(v, a)
  return v + a
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require("connecttest")
require('cardinalities')
require("user_modules/AppTypes")

--[[ Specific Notifications ]]
function Test:RegisterNotification()
  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(function(_, d)
      ptu = json.decode(d.binaryData)
    end)
  :Times(AtLeast(1))
  :Pin()
end

EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, d)
    log("SDL->HMI: SDL.OnStatusUpdate()", d.params.status)
  end)
:Times(AnyNumber())
:Pin()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.DeletePTUFile()
  if check_file_exists(policy_file_path .. "/" .. policy_file_name) then
    os.remove(policy_file_path .. "/" .. policy_file_name)
    print("Policy file is removed")
  end
end

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
  -- updating parameters in order to speed up the process
  ptu.policy_table.module_config.seconds_between_retries = { 1, 1, 1 }
  ptu.policy_table.module_config.timeout_after_x_seconds = 10
end

function Test.StorePTSInFile()
  local f = io.open(f_name, "w")
  f:write(json.encode(ptu))
  f:close()
end

function Test:Precondition_Successful_PTU()
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = policy_file_name }, f_name)
  log("MOB->SDL: SystemRequest")
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
  :Do(function(_, _)
      log("SUCCESS: SystemRequest")
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_StartNewMobileSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RegisterNotification()
  self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "HTTP" })
  :Do(function()
      log("SDL->MOB: OnSystemRequest")
      table.insert(timestamps, os.time())
    end)
  :Times(AnyNumber())
  :Pin()
  self.mobileSession2:ExpectNotification("OnSystemRequest", { requestType = "HTTP" })
  :Do(function()
      log("SDL->MOB2: OnSystemRequest")
      table.insert(timestamps, os.time())
    end)
  :Times(AnyNumber())
  :Pin()
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
end

Test["TestStep_Starting waiting cycle [" .. attempts * 5 .. "] sec"] = function() end

for i = 1, attempts do
  Test["Waiting " .. i * 5 .. " sec"] = function()
    os.execute("sleep 5")
  end
end

function Test.TestStep_ShowTimeouts()
  print("--- Seconds between retries ----------------------")
  for i = 2, #timestamps do
    local t = timestamps[i] - timestamps[i - 1]
    table.insert(r_actual, t)
    print(i - 1 .. ": " .. t)
  end
  print("--------------------------------------------------")
end

function Test:TestStep_ValidateResult()
  for i = 1, #r_expected do
    if (r_actual[i] < get_min(r_expected[i], accuracy))
    or (r_actual[i] > get_max(r_expected[i], accuracy))
    then
      self:FailTestCase("Expected timeout: " .. r_expected[i] .. ", got: " .. r_actual[i])
    end
  end
end

function Test.Test_ShowSequence()
  show_log()
end

--[[ Postconditions ]]

commonFunctions:newTestCasesGroup("Postconditions")

function Test.Clean()
  os.remove(f_name)
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
