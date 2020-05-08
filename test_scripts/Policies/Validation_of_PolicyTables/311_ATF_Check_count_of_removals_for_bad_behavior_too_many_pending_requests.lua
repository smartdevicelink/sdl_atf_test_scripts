---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and "count_of_removals_for_bad_behavior" update
--
-- Description:
-- In case an application has been unregistered with any of:
-- -> TOO_MANY_PENDING_REQUESTS,
-- -> TOO_MANY_REQUESTS,
-- -> REQUEST_WHILE_IN_NONE_HMI_LEVEL resultCodes,
-- Policy Manager must increment "count_of_removals_for_bad_behavior" section value
-- of Local Policy Table for the corresponding application.

-- Pre-conditions:
-- a. SDL and HMI are started
-- b. Application with appID is in any HMILevel other than NONE

-- Action:
-- Application is sending more requests than AppTimeScaleMaxRequests in AppRequestsTimeScale milliseconds:
-- appID->AnyRPC()

-- Expected:
-- Application is unregistered: SDL->appID: OnAppUnregistered(TOO_MANY_REQUESTS)
-- PoliciesManager increments value of <count_of_removals_for_bad_behavior>
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local utils = require ('user_modules/utils')

-- local variables
local count_of_requests = 10
local start_time = 0
local finish_time = 0

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

local connectMobile_Orig = Test.connectMobile
function Test:connectMobile()
  local ret = connectMobile_Orig(self)
  ret:Do(function()
      self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
        { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() }} )
      utils.wait(500)
    end)
  return ret
end

commonPreconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("FrequencyCount", count_of_requests)
commonFunctions:write_parameter_to_smart_device_link_ini("FrequencyTime", "5000")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ActivateApp()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName] })
  EXPECT_HMIRESPONSE(requestId1)
  :Do(function(_, d1)
      if d1.result.isSDLAllowed ~= true then
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(requestId2)
        :Do(function()
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_, d2)
                self.hmiConnection:SendResponse(d2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
                self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
              end)
          end)
      end
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

local received = false

function Test:RegisterNotification()
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered")
  :Do(function(_, d)
      if d.payload.reason == "TOO_MANY_REQUESTS" then
        received = true
      end
    end)
  :Pin()
  :Times(AnyNumber())
end

local numRq = 0
local numRs = 0

function Test.DelayBefore()
  commonTestCases:DelayedExp(5000)
  RUN_AFTER(function() start_time = timestamp() end, 5000)
end

for i = 1, count_of_requests + 1 do
  Test["RPC_" .. string.format("%02d", i)] = function(self)
    commonTestCases:DelayedExp(50)
    if not received then
      local cid = self.mobileSession:SendRPC("ListFiles", { })
      numRq = numRq + 1
      if numRq <= count_of_requests then
        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
        :Do(function() numRs = numRs + 1 end)
      end
    end
  end
end

function Test.DelayAfter()
  finish_time = timestamp()
  commonTestCases:DelayedExp(5000)
end

function Test:CheckTimeOut()
  local processing_time = finish_time - start_time
  print("Processing time: " .. processing_time)
  if processing_time > 5000 then
    self:FailTestCase("Processing time is more than 5 sec.")
  end
end

function Test:CheckAppIsUnregistered()
  print("Number of Sent RPCs: " .. numRq)
  print("Number of Responses: " .. numRs)
  if not received then
    self:FailTestCase("OnAppInterfaceUnregistered(TOO_MANY_REQUESTS) is not received")
  else
    print("OnAppInterfaceUnregistered(TOO_MANY_REQUESTS) is received")
  end
end

function Test:CheckRAINoSuccess()
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered"):Times(0)
  self.mobileSession:ExpectResponse(corId, { success = false, resultCode = "TOO_MANY_PENDING_REQUESTS" }):Times(1)
  self.mobileSession:ExpectNotification("OnHMIStatus"):Times(0)
  self.mobileSession:ExpectNotification("OnPermissionsChange"):Times(0)
  commonTestCases:DelayedExp(3000)
end

function Test:Check_TOO_MANY_REQUESTS_in_DB()
  local db_path = commonPreconditions:GetPathToSDL() .. "storage/policy.sqlite"
  local sql_query = "SELECT count_of_removals_for_bad_behavior FROM app_level WHERE application_id = '" .. config.application1.registerAppInterfaceParams.fullAppID .. "'"
  local exp_result = {"1"}
  if commonFunctions:is_db_contains(db_path, sql_query, exp_result) == false then
    self:FailTestCase("DB doesn't include expected value")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.RestoreFiles()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end

function Test.StopSDL()
  StopSDL()
end

return Test
