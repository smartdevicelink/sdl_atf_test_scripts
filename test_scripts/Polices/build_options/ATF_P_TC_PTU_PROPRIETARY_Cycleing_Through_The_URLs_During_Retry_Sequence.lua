---------------------------------------------------------------------------------------------
-- PROPRIETARY flow
-- Requirement summary:
-- [PolicyTableUpdate] Cycleing through the URLs during retry sequence
--
-- Description:
-- The policies manager shall cycle through the list of URLs, using the next one in the list
-- for every new policy table request over a retry sequence. In case of the only URL in Local Policy Table,
-- it must always be the destination for a Policy Table Snapshot.
--
-- Preconditions
-- 1. Preapre specific PTU file with additional URLs for app
-- 2. LPT is updated -> SDL.OnStatusUpdate(UP_TO_DATE)
-- Steps:
-- 1. Register new app -> new PTU sequence started and it can't be finished successfully
-- 2. Verify url parameter of OnSystemRequest() notification for each cycle
--
-- Expected result:
-- Url parameter is taken cyclically from list of available URLs
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
local ptu_file = "files/jsons/Policies/build_options/ptu_18269.json"
local sequence = { }
local attempts = 16
local r_expected = {
  "http://policies.domain1.ford.com/api/policies",
  "http://policies.domain2.ford.com/api/policies",
"http://policies.domain3.ford.com/api/policies"}
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

--[[ General Precondition before ATF start ]]
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("PROPRIETARY")
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")
config.defaultProtocolVersion = 2

--[[ Specific Notifications ]]
EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, _)
    -- log("SDL->HMI: SDL.OnStatusUpdate()", d.params.status)
  end)
:Times(AnyNumber())
:Pin()

EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
:Do(function(_, _)
    log("SDL->HMI: BC.PolicyUpdate()")
  end)
:Times(AnyNumber())
:Pin()

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

function Test:RegisterNotificationApp1()
  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(function(_, d)
      log("SDL->MOB: OnSystemRequest()", d.payload.requestType, d.payload.url)
      table.insert(r_actual, d.payload.url)
    end)
  :Times(AnyNumber())
  :Pin()
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
    end)
end

Test["Starting waiting cycle [" .. attempts * 5 .. "] sec"] = function() end

for i = 1, attempts do
  Test["Waiting " .. i * 5 .. " sec"] = function()
    os.execute("sleep 5")
  end
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

function Test:ValidateResult()
  for i = 1, 3 do
    if r_expected[i] ~= r_actual[i] then
      local m = table.concat({"\nExpected url:\n", r_expected[i], "\nActual:\n", tostring(r_actual[i]), "\n"})
      self:FailTestCase(m)
    end
  end
end

return Test
