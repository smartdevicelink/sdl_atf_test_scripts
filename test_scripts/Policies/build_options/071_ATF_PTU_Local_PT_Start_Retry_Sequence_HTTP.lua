---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Local Policy Table retry sequence start
-- [HMI API] OnStatusUpdate
--
-- Description:
-- In case PoliciesManager does not receive the Updated PT during time defined in
-- "timeout_after_x_seconds" section of Local PT, it must start the retry sequence.
--
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- PTU to be received satisfies data dictionary requirements
-- PTU omits "consumer_friendly_messages" section
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
--
-- 2. Performed steps
-- SDL->app: OnSystemRequest ('url', requestType:HTTP, fileType="JSON")
--
-- Expected result:
-- Timeout expires and retry sequence started
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")

--[[ Local Variables ]]
local sequence = { }
local attempts = 15
local timestamps = { }
local r_expected = 61
local r_actual
local r_expected_status = { "UPDATE_NEEDED", "UPDATING", "UPDATE_NEEDED", "UPDATING" }
local r_actual_status = { }

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
Test = require("user_modules/connecttest_resumption")
require('cardinalities')
require("user_modules/AppTypes")

config.defaultProtocolVersion = 2

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:RAI()
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function(_, d1)
      self.applications[config.application1.registerAppInterfaceParams.fullAppID] = d1.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
      :Do(
        function(_, d2)
          log("SDL->HMI: SDL.OnStatusUpdate", d2.params.status)
          table.insert(r_actual_status, d2.params.status)
        end)
      :Times(AnyNumber())
      :Pin()
      self.mobileSession:ExpectNotification("OnSystemRequest")
      :Do(
        function(_, d2)
          if d2.payload.requestType == "HTTP" then
            log("SDL->MOB: OnSystemRequest")
            table.insert(timestamps, os.time())
          end
        end)
      :Times(AnyNumber())
      :Pin()
    end)
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

Test["TestStep_Starting waiting cycle [" .. attempts * 5 .. "] sec"] = function() end

for i = 1, attempts do
  Test["Waiting " .. i * 5 .. " sec"] = function()
    os.execute("sleep 5")
  end
end

function Test.TestStep_ShowTimeouts()
  print("--- Seconds between retries ----------------------")
  if( #timestamps ~= 0 and timestamps[2] ~= nil and timestamps[1] ~= nil ) then
    r_actual = timestamps[2] - timestamps[1]
  end
  print(tostring(r_actual))
  print("--------------------------------------------------")
end

function Test:TestStep_Validate_Timeouts()
  if ( r_actual ~= nil ) then
    if (r_actual < r_expected - 5) or (r_actual > r_expected + 5) then
      local msg = table.concat({ "Expected timeout: '", r_expected, "', got: '", r_actual, "'" })
      self:FailTestCase(msg)
    end
  else
    self:FailTestCase("Expected timeout is not calculated.")
  end
end

function Test:TestStep_Validate_Status()
  if not is_table_equal(r_expected_status, r_actual_status) then
    local msg = table.concat({
        "\nExpected statuses:\n", commonFunctions:convertTableToString(r_expected_status, 1),
        "\nActual:\n", commonFunctions:convertTableToString(r_actual_status, 1)})
    self:FailTestCase(msg)
  end
end

function Test.Test_ShowSequence()
  show_log()
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
