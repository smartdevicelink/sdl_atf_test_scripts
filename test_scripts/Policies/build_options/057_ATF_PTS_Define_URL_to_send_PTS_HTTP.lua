---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Define the URL(s) the PTS will be sent to
--
-- Description:
-- To get the urls PTS should be transfered to, Policies manager must refer PTS "endpoints" section,
-- key "0x07" for the appropriate <app id> which was chosen for PTS transferring
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- 2. Performed steps
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
--
-- Expected result:
-- SDL.GetURLs({urls[] = default}, (<urls>, appID))
-- SDL-> <app ID> ->OnSystemRequest(params, url, timeout)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local json = require("modules/json")
local mobile_session = require('mobile_session')
local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")

--[[ Local Variables ]]
local sequence = { }
local ptu_file_name = os.tmpname()
local ptu
local r_actual_app
local r_actual_url
local r_expected = { "http://policies.domain1.com/api/policies", "http://policies.domain2.com/api/policies"}

--[[ Local Functions ]]
local function get_ptu()
  if(ptu == nil) then
    local config_path = commonPreconditions:GetPathToSDL()
    local pathToFile = config_path .. 'sdl_preloaded_pt.json'

    local file = io.open(pathToFile, "r")
    local json_data = file:read("*all")
    file:close()

    ptu = json.decode(json_data)
  end
end

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

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Specific Notifications ]]
EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, d)
    log("SDL->HMI: N: SDL.OnStatusUpdate", d.params.status)
  end)
:Times(AnyNumber())
:Pin()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:Precondition_RAI()
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
  :Do(function(_,data) self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID end)

  EXPECT_RESPONSE(CorIdRegister, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

  EXPECT_NOTIFICATION("OnSystemRequest")
  :Do(function(_,data)
      print("SDL->MOB1: OnSystemRequest, requestType: " .. data.payload.requestType)
      if(data.payload.requestType == "HTTP") then
        if(data.binaryData ~= nil and data.binaryData ~= "") then
          ptu = json.decode(data.binaryData)
        else
          get_ptu()
          self:FailTestCase("Binary data is empty. Preloaded file will be used")
        end
      end
    end)
  :Times(2)

end

function Test:ValidatePTS()
  if(ptu == nil or ptu == "") then
    get_ptu()
    self:FailTestCase("Binary data is empty. Preloaded file will be used")
  else
    if ptu.policy_table.consumer_friendly_messages.messages then
      self:FailTestCase("Expected absence of 'consumer_friendly_messages.messages' section in PTS")
    end
  end
end

function Test.UpdatePTS()
  ptu.policy_table.device_data = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.vehicle_data = nil
  ptu.policy_table.app_policies["0000001"] = { keep_context = false, steal_focus = false, priority = "NONE", default_hmi = "NONE" }
  ptu.policy_table.app_policies["0000001"]["groups"] = { "Base-4", "Base-6" }
  -- ptu.policy_table.app_policies["0000001"]["RequestType"] = { "HTTP" }
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  ptu.policy_table.module_config.endpoints["0x07"]["0000001"] = { r_expected[1] }
  ptu.policy_table.module_config.endpoints["0x07"]["0000002"] = { r_expected[2] }
end

function Test.StorePTSInFile()
  local f = io.open(ptu_file_name, "w")
  f:write(json.encode(ptu))
  f:close()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:PTU()
  local policy_file_name = "PolicyTableUpdate"
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = policy_file_name }, ptu_file_name)
  log("MOB->SDL: RQ: SystemRequest")
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
  :Do(function(_, data)
      log("SDL->MOB: RS: "..data.payload.resultCode..": SystemRequest")
    end)
end

function Test:CheckStatus()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  log("HMI->SDL: RQ: SDL.GetStatusUpdate")
  EXPECT_HMIRESPONSE(reqId, { status = "UP_TO_DATE" })
  log("HMI->SDL: RS: UP_TO_DATE: SDL.GetStatusUpdate")
end

function Test:Precondition_StartSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:RegisterApp_2()
  commonTestCases:DelayedExp(5000)
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_, data)
      self.applications[data.params.application.appName] = data.params.application.appID
    end)
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })

  self.mobileSession2:ExpectNotification("OnSystemRequest"):Times(Between(1,2))
  :Do(function(_,data)
      print("SDL->MOB2: OnSystemRequest, requestType: " .. data.payload.requestType)
      if(data.payload.requestType == "HTTP") then
        if(data.payload.url ~= nil) then
          r_actual_app = 2
          r_actual_url = data.payload.url
        end
      end
    end)

  self.mobileSession:ExpectNotification("OnSystemRequest"):Times(Between(0,1))
  :Do(function(_,data)
      print("SDL->MOB1: OnSystemRequest, requestType: " .. data.payload.requestType)
      if(data.payload.requestType == "HTTP") then
        if(data.payload.url ~= nil) then
          r_actual_app = 1
          r_actual_url = data.payload.url
        end
      end
    end)
  commonTestCases:DelayedExp(10000)
end

function Test:ValidateResult()
  print("AppId: " .. tostring(r_actual_app))
  print("URL: " .. tostring(r_actual_url))
  if not r_actual_app or not r_actual_url then
    self:FailTestCase("Expected OnSystemRequest notification was NOT sent to any of registered applications")
  elseif r_actual_url ~= r_expected[r_actual_app] then
    local msg = table.concat({
        "\nExpected URL is '", r_expected[r_actual_app], "'",
        "\nActual is '", r_actual_url, "'" })
    self:FailTestCase(msg)
  end
end

function Test.Test_ShowSequence()
  show_log()
end

--[[ Postconditions ]]

function Test.Clean()
  os.remove(ptu_file_name)
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
