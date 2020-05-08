---------------------------------------------------------------------------------------------
-- HTTP flow
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
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")

--[[ Local Variables ]]
local ptu_file = "files/jsons/Policies/build_options/ptu_18269.json"
local sequence = { }
local attempts = 6
local r_expected = {
  commonFunctions.getURLs("0x07")[1],
  "http://policies.domain1.ford.com/api/policies",
  "http://policies.domain2.ford.com/api/policies",
  "http://policies.domain3.ford.com/api/policies"
}
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
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")
config.defaultProtocolVersion = 2
local startSession = Test.startSession

--[[ Specific Notifications ]]
function Test:startSession()
  startSession(self)
  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Do(function(_, d)
      if d.payload.requestType == "HTTP" then
        log("SDL->MOB1: OnSystemRequest()", d.payload.requestType, tostring(d.payload.url) )
        table.insert(r_actual, d.payload.url)
      end
    end)
  :Times(AnyNumber())
  :Pin()
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Update_LPT()
  local policy_file_name = "PolicyTableUpdate"
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = policy_file_name }, ptu_file)
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
end

function Test:ActivateNewApp()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"] })
  EXPECT_HMIRESPONSE(RequestId)
  self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" })
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:StartNewMobileSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RegisterNotification()
  self.mobileSession2:ExpectNotification("OnSystemRequest")
  :Do(function(_, d)
      if d.payload.requestType == "HTTP" then
        log("SDL->MOB2: OnSystemRequest()", d.payload.requestType, d.payload.url)
        table.insert(r_actual, d.payload.url)
      end
    end)
  :Times(AnyNumber())
  :Pin()
end

function Test:RegisterNewApp()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
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
  local function contains(pTbl, pItem)
    for _, e in pairs(pTbl) do
      if e == pItem then return true end
    end
    return false
  end
  if #r_actual ~= #r_expected then
    self:FailTestCase("\nExpected number of requests: " .. #r_expected .. ", actual: " .. #r_actual)
  else
    for _, e in pairs(r_expected) do
      if not contains(r_actual, e) then
        self:FailTestCase("\nExpected item '" .. e .."' is not found")
      end
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
