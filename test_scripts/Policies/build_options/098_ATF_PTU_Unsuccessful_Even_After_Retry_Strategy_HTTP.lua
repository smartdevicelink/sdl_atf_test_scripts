---------------------------------------------------------------------------------------------
-- HTTP flow
-- Requirement summary:
-- [PolicyTableUpdate] PTU unsuccessful even after Retry strategy - initiate PTU the next ignition cycle
--
-- Description:
-- In case the policy table exchange is unsuccessful after the retry strategy is completed,
-- the Policy Manager must initiate the new PT exchange sequence upon the next ignition on.
--
-- Preconditions
-- 1. SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- 2. LPT is updated: params 'timeout_after_x_seconds' and 'seconds_between_retries' in order to speed up the test

-- Steps:
-- 1. Register new app -> PTU sequence started
-- 2. PTU retry sequence failed -> last status of SDL.OnStatusUpdate(UPDATE_NEEDED)
-- 3. IGN_OFF
-- 4. IGN_ON
-- 5. Register app -> PTU sequence started
-- 6. Verify first status of SDL.OnStatusUpdate()
-- 7. Verify that PTS is created
--
-- Expected result:
-- Status is UPDATE_NEEDED and PTS is sent as binary data of OnSystemRequest to Mobile
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local mobile_session = require('mobile_session')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/build_options/retry_seq.json")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Connect_device()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_OnStatusUpdate_UPDATE_NEEDED_new_PTU_request()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = config.application1.registerAppInterfaceParams.appName}})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)

  EXPECT_NOTIFICATION("OnSystemRequest")
  :Times(2)

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:TestStep_Retry_Timeout_Expiration()
  local total_time =  185000
  print("Waiting " .. total_time .. "ms")

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
    {status = "UPDATE_NEEDED"}, {status = "UPDATING"},
    {status = "UPDATE_NEEDED"}, {status = "UPDATING"},
    {status = "UPDATE_NEEDED"}, {status = "UPDATING"},
    {status = "UPDATE_NEEDED"}, {status = "UPDATING"},
    {status = "UPDATE_NEEDED"}, {status = "UPDATING"},
    {status = "UPDATE_NEEDED"})
  :ValidIf(function(exp, data)
      print("[" .. atf_logger.formated_time(true) .. "] " .. "SDL->HMI: SDL.OnStatusUpdate()"
        .. ": " .. string.format("%02d", exp.occurences) .. ": " .. data.params.status)
      if exp.occurences == 11 and data.params.status ~= "UPDATE_NEEDED" then
        return false, "Last SDL.OnStatusUpdate is not UPDATE_NEEDED"
      end
      return true
    end)
  :Times(11)
  :Timeout(total_time)
end

function Test:Ignition_Off()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      StopSDL()
    end)
end

function Test.Ignition_On()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:InitHMI()
  self:initHMI()
end

function Test:InitHMI_onReady()
  self:initHMI_onReady()
end

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartMobileSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:TestStep_OnStatusUpdate_UPDATE_NEEDED_new_PTU_request()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = config.application1.registerAppInterfaceParams.appName}})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)

  EXPECT_NOTIFICATION("OnSystemRequest")
  :ValidIf(function(_, data)
      if (data.payload.requestType == "HTTP") then
        if (data.binaryData ~= nil) and (data.binaryData ~= "") then
          return true
        end
        return false, "PTS was not sent to Mobile in payload of OnSystemRequest"
      end
      return true
    end)
  :Times(2)

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_files()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
