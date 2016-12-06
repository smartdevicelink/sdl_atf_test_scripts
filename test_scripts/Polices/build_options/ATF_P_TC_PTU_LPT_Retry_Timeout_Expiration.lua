---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] Local Policy Table retry timeout expiration
--
-- Description:
-- In case the corresponding retry timeout expires, PoliciesManager must send the new PTU request to mobile app
-- until successful Policy Table Update has finished or the number of retry attempts is limited by the number of elements
-- in "seconds_between_retries" section of LPT.
--
-- Preconditions
-- 1. Register app_1 and perform PTU with updated 'timeout_after_x_seconds' and 'seconds_between_retries' params in order to run test faster
-- 2. Make sure PTU finished successfully (UP_TO_DATE)
-- Steps:
-- 1. Register app_2 and start PTU, which can't be finished successfully
-- 2. Check timestamps of BC.PolicyUpdate() requests
-- 3. Calculate timeouts
--
-- Expected result:
-- Timeouts correspond to 'timeout_after_x_seconds' and 'seconds_between_retries' params
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
local ptu_file = "files/jsons/Policies/build_options/ptu_18243.json"
local sequence = { }
local accuracy = 2
local r_expected = { 1, 30, 45, 71, 101 }
local r_actual = { }

--[[ Local Functions ]]
local function timestamp()
  local f = io.popen("date +%H:%M:%S.%3N")
  local o = f:read("*all")
  f:close()
  o = o:gsub("\n", "")
  return o
end

local function log(e, p)
  table.insert(sequence, { ts = os.time(), event = e, timeout = p, ts2 = timestamp() })
end

local function get_min(v, a)
  if v - a < 0 then return 1 end
  return v - a
end

local function get_max(v, a)
  return v + a
end

--[[ General Precondition before ATF start ]]
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("PROPRIETARY")
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")
config.defaultProtocolVersion = 2

--[[ Specific Notifications ]]
EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
:Do(function(_, d)
    log("SDL->HMI: BC.PolicyUpdate", d.params.timeout)
  end)
:Times(AnyNumber())
:Pin()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:PTU_1()
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
              requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = { "StatusUpToDate" }})
              EXPECT_HMIRESPONSE(requestId)
            end)
        end)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

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

function Test:PTU_2()
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })
      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function(_, _)
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file)
          EXPECT_RESPONSE(corIdSystemRequest, { success = false, resultCode = "GENERIC_ERROR" })
        end)
    end)
end

Test["Starting waiting cycle [" .. 55 * 5 .. "] sec"] = function() end

for i = 1, 55 do
  Test["Waiting " .. i * 5 .. " sec"] = function()
    os.execute("sleep 5")
  end
end

function Test.ShowSequence()
  print("--- Sequence -------------------------------------")
  for k, v in pairs(sequence) do
    print(k .. ": " .. v.ts2 .. ": " .. v.ts .. ": " .. v.event .. ": " .. v.timeout)
  end
  print("--------------------------------------------------")
end

function Test.ShowTimeouts()
  print("--- Timeouts -------------------------------------")
  for i = 2, #sequence do
    local t = sequence[i].ts - sequence[i - 1].ts
    r_actual[i - 1] = t
    print(i - 1 .. ": " .. t)
  end
  print("--------------------------------------------------")
end

function Test:ValidateResult()
  for i = 1, 5 do
    if (r_actual[i] < get_min(r_expected[i], accuracy)) or (r_actual[i] > get_max(r_expected[i], accuracy)) then
      self:FailTestCase("Expected timeout: " .. r_expected[i] .. ", got: " .. r_actual[i])
    end
  end
end

return Test
