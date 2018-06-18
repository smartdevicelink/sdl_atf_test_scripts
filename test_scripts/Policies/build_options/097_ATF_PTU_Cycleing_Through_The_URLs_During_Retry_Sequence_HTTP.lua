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
--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require("user_modules/utils")
local actions = require("user_modules/sequences/actions")
local json = require("modules/json")

local ptu_table = utils.jsonFileToTable(commonPreconditions:GetPathToSDL() .. "sdl_preloaded_pt.json")
ptu_table.policy_table.module_config.preloaded_pt = nil
ptu_table.policy_table.consumer_friendly_messages = nil
ptu_table.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
ptu_table.policy_table.module_config.preloaded_date = nil
ptu_table.policy_table.module_config.timeout_after_x_seconds = 10
ptu_table.policy_table.module_config.seconds_between_retries = { 1, 5, 10, 15, 20 }
ptu_table.policy_table.module_config.endpoints["0x07"] = {
  default = { "http://policies.telematics.ford.com/api/policies" },
  [actions.getConfigAppParams(1).appID] = {
    "http://policies.domain1.ford.com/api/policies",
    "http://policies.domain2.ford.com/api/policies",
    "http://policies.domain3.ford.com/api/policies"
  }
}

local ptu_file = os.tmpname()
utils.tableToJsonFile(ptu_table, ptu_file)
local sequence = { }
local attempts = 16
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

--[[ Specific Notifications ]]
function Test:RegisterNotification()
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
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = policy_file_name }, ptu_file)
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
end

function Test:ActivateApp()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

-- [[ Test ]]
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

for i = 1, 4 do
  Test["ValidateResult" .. i] = function(self)
    if(r_actual[i] ~= nil) then
      if r_expected[i] ~= r_actual[i] then
        local m = table.concat({"\nExpected url:\n", tostring(r_expected[i]), "\nActual:\n", tostring(r_actual[i]), "\n"})
        self:FailTestCase(m)
      end
    else
      self:FailTestCase("Actual url is empty")
    end
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
