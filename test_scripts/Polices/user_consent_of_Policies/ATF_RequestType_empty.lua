---------------------------------------------------------------------------------------------
-- Requirement summary:
--    [Policies] PTU "RequestType" array is empty
--
-- Description:
--    PTU with "<appID>" policies comes and "RequestType" array is empty
--     1. Used preconditions:
--		Unregister default application
-- 		Register application
--		Activate application
--
--     2. Performed steps
--		Perform PTU with empty RequestType value for app
--		Send RPC from app
--
-- Expected result:
--  	  Policies Manager must:
--		leave "RequestType" as empty array;
--	        allow any request type for such <appID> app
---------------------------------------------------------------------------------------------
--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()

function Test:Precondition_Unregister_default_app()
  local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SyncProxyTester"], unexpectedDisconnect = false})
  EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
  :Timeout(2000)
end

function Test:Precondition_Register_app()
  commonTestCases:DelayedExp(3000)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
  self.HMIAppID = data.params.application.appID
  end)
  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end)
end

function Test:Precondition_Activate_app()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
  if data.result.isSDLAllowed ~= true then
    local RequestIdGetMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
    EXPECT_HMIRESPONSE(RequestIdGetMessage)
    :Do(function()
    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
    EXPECT_HMICALL("BasicCommunication.ActivateApp")
    :Do(function()
    self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
    :Times(AnyNumber())
    end)
  end
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep1_PTU_empty_requestType()
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
  :Do(function()
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
  {
    requestType = "PROPRIETARY",
    fileName = "filename"
  }
  )
  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
  :Do(function()
  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
  {
    fileName = "PolicyTableUpdate",
    requestType = "PROPRIETARY"
  }, "files/PTU_RequestType_emty.json")
  local systemRequestId
  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Do(function(_,data)
  systemRequestId = data.id
  self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
  {
    policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
  })
  local function to_run()
    self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
  end
  RUN_AFTER(to_run, 500)
  end)
  :Do(function()
  self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
  end)
  end)
  end)
end

function Test:TestStep2_Check_RPC_processed()
  local RequestIDAddCommand = self.mobileSession:SendRPC("AddCommand",
  {
    cmdID = 111,
    menuParams =
    {
      position = 1,
      menuName ="Command111"
    }
  })
  EXPECT_HMICALL("UI.AddCommand",
  {
    cmdID = 111,
    menuParams =
    {
      position = 1,
      menuName ="Command111"
    }
  })
  :Do(function(_,data)
  self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {})
  end)
  EXPECT_RESPONSE(RequestIDAddCommand, { success = true, resultCode = "SUCCESS" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_SDLForceStop()
  commonFunctions:SDLForceStop()
end
