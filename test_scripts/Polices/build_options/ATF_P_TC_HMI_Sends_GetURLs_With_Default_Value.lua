-- Requirement summary:
-- In case HMI sends GetURLs and no apps registered SDL must return only default url
--
-- Description:
-- In case HMI sends GetURLs (<serviceType>) AND NO mobile apps registered
-- SDL must:
-- check "endpoint" section in PolicyDataBase and return only default url
-- (meaning: SDL must skip others urls which relate to not registered apps)
--
-- Preconditions:
-- 1. Update LPT -> add additional URLs in endpoints for app_1
-- 2. LPT is updated -> SDL.OnStatusUpdate(UP_TO_DATE)
-- Steps:
-- 1. Register new app
-- 2. Send SDL.GetURLS() request
-- 3. Verify URLs in response
--
-- Expected result:
-- Default URL is provided
-------------------------------------------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForBuildingSDLPolicyFlag = require('user_modules/shared_testcases/testCasesForBuildingSDLPolicyFlag')

--[[ Local Variables ]]
local sequence = { }
local ptu_file = "files/jsons/Policies/build_options/ptu_14832.json"

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

local function ptu(self, file)
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local policy_file_name = "PolicyTableUpdate"
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })
      self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, _)
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, file)
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

--[[ General Precondition before ATF start ]]
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("PROPRIETARY")
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Specific Notifications ]]
EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
:Do(function(_, d)
    log("SDL->HMI: SDL.OnStatusUpdate()", d.params.status)
  end)
:Times(AnyNumber())
:Pin()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:PTU()
  ptu(self, ptu_file)
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

function Test:PTU()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, _)
      local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
      EXPECT_HMIRESPONSE(requestId, { result = { urls = { }}})
      :ValidIf(function(_, d)
          local r_expected = "http://policies.telematics.ford.com/api/policies"
          local r_actual = d.result.urls[1]
          if r_expected ~= r_actual then
            local msg = table.concat({"\nExpected: ", r_expected, "\nActual: ", tostring(r_actual)})
            return false, msg
          end
          return true
        end)
    end)
end

function Test.Test_ShowSequence()
  show_log()
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
