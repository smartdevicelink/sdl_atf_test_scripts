---------------------------------------------------------------------------------------------
-- Requirement summary:
-- DISALLOWED <app id> policies and "RequestType" validation
--
-- Description:
-- In case the <app id> policies are assigned to the application,
-- PoliciesManager must ignore RPC with requestTypes different from "RequestType" defined in <app id> section.
-- SDL must respond with (resultCode:DISALLOWED, success:false) to mobile application.
-- 1. Used preconditions:
-- a) Set SDL to first life cycle state.
-- b) Register application, activate and consent device
-- c) Update Policy with requestType = "PROPRIETARY" for specific app section
-- 2. Performed steps:
-- b) Send SystemRequest with requestType = "PROPRIETARY"
-- c) Send SystemRequest with requestType = "HTTP"
--
-- Expected result:
-- SDL allow SystemRequest with requestType = "PROPRIETARY" and disallow SystemRequest with requestType = "HTTP"
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_connect_device.lua")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_connect_device')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require("mobile_session")

--[[ Preconditions ]]
--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_Connect_device()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  if utils.getDeviceTransportType() == "WIFI" then
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

function Test:Precondition_StartNewSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:Precondition_RegisterApp()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
        majorVersion = 3,
        minorVersion = 0
      },
      appName = "SPT",
      isMediaApplication = true,
      languageDesired = "EN-US",
      hmiDisplayLanguageDesired = "EN-US",
      appID = "1234567",
      deviceInfo =
      {
        os = "Android",
        carrier = "Megafon",
        firmwareRev = "Name: Linux, Version: 3.4.0-perf",
        osVersion = "4.4.2",
        maxNumberRFCOMMPorts = 1
      }
    })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {
      application =
      {
        appName = "SPT",
        policyAppID = "1234567",
        isMediaApplication = true,
        hmiDisplayLanguageDesired = "EN-US",
        deviceInfo =
        {
          name = utils.getDeviceName(),
          id = utils.getDeviceMAC(),
          transportType = utils.getDeviceTransportType(),
          isSDLAllowed = false
        }
      }
    })
  :Do(function(_,data)
      self.applications["SPT"] = data.params.application.appID
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
end

function Test:Precondition_Activate_App_And_Consent_Device()
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["SPT"]})
      EXPECT_HMIRESPONSE(RequestId, { result = {
            code = 0,
            isSDLAllowed = false},
          method = "SDL.ActivateApp"})
      :Do(function(_,_)
          local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
          EXPECT_HMIRESPONSE(RequestId1,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          :Do(function(_,_)
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
              :Do(function(_,data1)
                  self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
                  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
                end)
            end)
        end)
end

function Test:Precondition_DeactivateApp()
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["SPT"], reason = "GENERAL"})
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "LIMITED"})
end

function Test:Preconditions_Update_Policy_With_RequestType_PROPRIETARY_For_Current_App()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
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
            }, "files/PTU_RequestType_for_app_1234567.json")
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
              RUN_AFTER(to_run, 800)
              self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
              EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
            end)
        end)
    end)
end

--[[ Test ]]
function Test:TestStep_User_Consents_New_Permissions_After_App_Activation()
  local RequestIdActivateApp = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["SPT"]})

  EXPECT_HMIRESPONSE(RequestIdActivateApp,
    { result = {
        code = 0,
        isPermissionsConsentNeeded = true,
        isAppPermissionsRevoked = false,
        isAppRevoked = false},
      method = "SDL.ActivateApp"})

  local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
  EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,
    { result = { code = 0,
        messages = {{ messageCode = "DataConsent"}},
        method = "SDL.GetUserFriendlyMessage"}})

  local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = self.applications["SPT"] })
  EXPECT_HMIRESPONSE(RequestIdListOfPermissions,
    { result = {
        code = 0,
        allowedFunctions = {{name = "New_permissions"}} },
      method = "SDL.GetListOfPermissions"})
  :Do(function(_,data)
      local functionalGroupID = data.result.allowedFunctions[1].id
      self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent",
        { appID = self.applications["SPT"], source = "GUI", consentedFunctions = {{name = "New_permissions", allowed = true, id = functionalGroupID} }})
    end)
  EXPECT_NOTIFICATION("OnPermissionsChange", {})
end

function Test:TestStep_UpdatePTS()
  testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
end

function Test:TestStep_Verify_app_id_section()
  local test_fail = false
  local request_consent = testCasesForPolicyTableSnapshot:get_data_from_PTS("app_policies.1234567.RequestType.1")

  if(request_consent ~= "PROPRIETARY") then
    commonFunctions:printError("Error: RequestType is not PROPRIETARY")
    test_fail = true
  end
  if(test_fail == true) then
    self:FailTestCase("Test failed. See prints")
  end
end

function Test:TestStep_SDL_Allow_SystemRequest_Of_PROPRIETARY_Type()

  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/icon.png")
  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
    end)
  self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})

end

function Test:TestStep_SDL_Disallow_SystemRequest_Of_HTTP_Type()

  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "HTTP"}, "files/icon.png")
  self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = false, resultCode = "DISALLOWED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test

