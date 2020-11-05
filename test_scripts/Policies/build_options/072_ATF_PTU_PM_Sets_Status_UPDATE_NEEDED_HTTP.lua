-- Requirements summary:
-- [PolicyTableUpdate][GENIVI] PoliciesManager changes status to “UPDATE_NEEDED”
--
-- Description:
-- PoliciesManager must change the status to “UPDATE_NEEDED” and notify HMI with OnStatusUpdate(“UPDATE_NEEDED”)
-- in case the timeout taken from "timeout_after_x_seconds" field of LocalPT or "timeout between retries"
-- is expired before PoliciesManager receives SystemRequest with PTU from mobile application.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Connect mobile phone over WiFi.
-- 2. Performed steps
-- Register new application to trigger PTU
-- SDL-> <app ID> ->OnSystemRequest(params, url, )
-- Timeout expires
--
-- Expected result:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')

--[[ Local variables ]]
local sequence = { }
local ts_on_system_request = 0
local ts_on_status_update = 0

local r_expected_timeout = 60

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
  print("--- Sequence -----------------------------------------------")
  for k, v in pairs(sequence) do
    local s = string.format("%03d", k) .. ": " .. v.ts .. ": " .. v.e
    for _, val in pairs(v.p) do
      if val then s = s .. ": " .. val end
    end
    print(s)
  end
  print("------------------------------------------------------------")
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RAI_PTU()
  print("Starting waiting cycle of 65 sec")
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  log("MOB->SDL: RQ: RegisterAppInterface")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function(_, d1)
      log("SDL->HMI: N: BC.OnAppRegistered")
      self.applications[config.application1.registerAppInterfaceParams.fullAppID] = d1.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}, {status = "UPDATE_NEEDED"}, {status = "UPDATING"})
      :Do(function(_, d)
          log("SDL->HMI: N: SDL.OnStatusUpdate", d.params.status)
          if d.params.status == "UPDATE_NEEDED" then
            ts_on_status_update = os.time()
          end
        end)
      :Times(4)
      :Timeout(65000)
    end)

      local onSystemRequestRecieved = false
      self.mobileSession:ExpectNotification("OnSystemRequest")
      :Do(
        function(e2, d2)
          print(e2.occurences .. ":" .. d2.payload.requestType)
          log("SDL->MOB: N: OnSystemRequest, RequestType: " .. d2.payload.requestType)
          if (not onSystemRequestRecieved) and (d2.payload.requestType == "HTTP") then
            onSystemRequestRecieved = true
            ts_on_system_request = os.time()
          end
        end)
      :Times(3) -- LOCK_SCREEN_ICON_URL, HTTP, HTTP
      :Timeout(65000)

  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(
    function()
      log("SDL->MOB: RS: RegisterAppInterface")
      self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      :Do(
        function(_ ,d)
          log("SDL->MOB: N: OnHMIStatus", d.payload.hmiLevel)
        end)
      self.mobileSession:ExpectNotification("OnPermissionsChange")
      :Do(
        function()
          log("SDL->MOB: N: OnPermissionsChange")
        end)
    end)

  commonTestCases:DelayedExp(65000) -- wait exchange_after_x_seconds(t0) + tollerance 5 sec
end

-- Test["Starting waiting cycle [" .. attempts * 5 .. "] sec"] = function() end

-- for i = 1, attempts do
-- Test["Waiting " .. i * 5 .. " sec"] = function()
-- os.execute("sleep 5")
-- end
-- end

function Test.ShowSequence()
  show_log()
end

function Test:ValidateResult()
  print("TS for OnSystemRequest: " .. tostring(ts_on_system_request))
  print("TS for SDL.OnStatusUpdate: " .. tostring(ts_on_status_update))
  if not ts_on_system_request then
    self:FailTestCase("Expected OnSystemRequest request was not sent")
  end
  if not ts_on_status_update then
    self:FailTestCase("Expected SDL.OnStatusUpdate(UPDATE_NEEDED) notification was not sent")
  end
  local r_actual_timeout = ts_on_status_update - ts_on_system_request
  print("Expected: " .. r_expected_timeout)
  print("Actual: " .. r_actual_timeout)
  -- tolerance 2 sec.
  if (r_actual_timeout < r_expected_timeout - 1) or (r_actual_timeout > r_expected_timeout + 1) then
    local msg = "\nExpected timeout '" .. r_expected_timeout .. "', actual '" .. r_actual_timeout .. "'"
    self:FailTestCase(msg)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Stop()
  StopSDL()
end

return Test
