--UNREADY: Need to add json file from https://github.com/smartdevicelink/sdl_atf_test_scripts/pull/363/
-- Also the sequence array is filled in with BasicCommunication.OnSystemRequest
-- r_actual also returns nil and this invalidates the whole check
-- Neees to be updated for scexonds between retries as well

---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] Policy Table Update retry timeout computation
--
-- Description:
--PoliciesManager must use the values from "seconds_between_retries" section of Local PT as the values to 
--computate the timeouts of retry sequense (that is, seconds to wait for the response). 
--
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: ON" flag, application with <appID_1> is running on SDL
-- PTU with updated 'timeout_after_x_seconds' and 'seconds_between_retries' params
-- is performed to speed up the test
-- PTU finished successfully (UP_TO_DATE)
-- 2. Performed steps
-- Trigger new PTU by registering Application 2
-- SDL -> mobile BC.OnSystemRequest (params, url)
-- PolicyTableUpdate won't come within futher defined 'timeout'
-- Check timestamps of BC.PolicyUpdate() requests
-- Calculate seconds_between_retries
--
-- Expected result: Retry sequence started:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED), PoliciesManager takes the timeouts for retry sequence from "seconds_between_retries" section of Local PT.
-- SDL->app ID: send SnapshotPT via OnSystemRequest
-- wait during timeout (e.g. 30s)
-- PTU not received
-- SDL->app ID: send SnapshotPT via OnSystemRequest
-- wait during t1 + timeout (e.g. 1s + 30s=31s)
-- PTU not received
-- SDL->app ID: send SnapshotPT via OnSystemRequest
-- wait during t2 + t1 + timeout (e.g. 5s + 31s + 30s=66s)
-- PTU not received
-- SDL->app ID: send SnapshotPT via OnSystemRequest
-- wait during t3 + t2 + timeout (e.g. 25s + 66s + 30s=121s)
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")

--[[ Local Variables ]]
local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
local policy_file_name = "PolicyTableUpdate"
local ptu_file = "files/jsons/Policies/build_options/ptu_18243.json"
local sequence = { }
local accuracy = 2
local seconds_between_retries = {1, 5, 10, 15, 20}
local timeout_after_x_seconds = 10
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
  print("Logging")
  table.insert(sequence, { ts = os.time(), event = e, timeout = p, ts2 = timestamp() })
end

local function get_min(v, a)
  if v - a < 0 then return 1 end
  return v - a
end

local function get_max(v, a)
  return v + a
end

local function computation()
  local tprev = 0
  local tout = 0
  for i=1,5 do
    tout = tprev + seconds_between_retries[i] + timeout_after_x_seconds
    tprev = tout
  end
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require("connecttest")
require('cardinalities')
require("user_modules/AppTypes")

--[[ Specific Notifications ]]
EXPECT_HMICALL("BasicCommunication.OnSystemRequest")
:Do(function(_, d)
    log("SDL->HMI: BC.OnSystemRequest", d.params.timeout)
  end)
:Times(AnyNumber())
:Pin()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Successful_PTU()
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
end

function Test:TestStep_Second_PTU()
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

Test["TestStep_Starting waiting cycle [" .. 55 * 5 .. "] sec"] = function() end

for i = 1, 3 do
  Test["Waiting " .. i * 5 .. " sec"] = function()
    os.execute("sleep 5")
  end
end

function Test.TestStep_Computatuin()
  computation()
end

function Test.TestStep_ShowSequence()
  print("--- Sequence -------------------------------------")
  for k, v in pairs(sequence) do
    print(k .. ": " .. v.ts2 .. ": " .. v.ts .. ": " .. v.event .. ": " .. v.timeout)
  end
  print("--------------------------------------------------")
end

function Test.TestStep_ShowTimeouts()
  print("--- Timeouts -------------------------------------")
  for i = 2, #sequence do
    local t = sequence[i].ts - sequence[i - 1].ts
    r_actual[i - 1] = t
    print(i - 1 .. ": " .. t)
  end
  print("--------------------------------------------------")
end

function Test:TestStep_ValidateResult()
  for i = 1, 5 do
    print("r_actual ", r_actual[i])
    print("r_expected ", r_expected[i])
    if (r_actual[i] < get_min(r_expected[i], accuracy))
    or (r_actual[i] > get_max(r_expected[i], accuracy))
    then
      self:FailTestCase("Expected timeout: " .. r_expected[i] .. ", got: " .. r_actual[i])
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test:Postcondition_Force_Stop_SDL()
  commonFunctions:SDLForceStop(self)
end

return Test