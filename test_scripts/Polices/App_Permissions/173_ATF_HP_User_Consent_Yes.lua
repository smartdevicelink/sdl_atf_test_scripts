---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: User-consent "YES"
-- [Mobile API] OnPermissionsChange notification
-- [HMI API] OnAppPermissionConsent notification
--
-- Description:
-- On getting user consent information from HMI and storage into LocalPolicyTable ,
-- SDL must notify an application about the current permissions active on HMI via onPermissionsChange() notification.
-- Check that SDL ask user for consent new permissions and apply them
-- 1. Used preconditions:
-- a) Delete policy.sqlite file, app_info.dat files
-- b) <Device> is connected to SDL and consented by the User, <App> is running on that device.
-- c) <App> is registered with SDL and is present in HMI list of registered aps.
-- d) Local PT has permissions for <App> that require User`s consent.
-- 2. Performed steps
-- a) User choose <App> in the list of registered aps on HMI.
-- b) The User allows definite permissions.
-- c) Send RPCs which allow by user and disallow by policy.
--
-- Expected result:
-- a) HMI->SDL: SDL.ActivateApp {appID}
-- SDL->HMI: SDL.ActivateApp_response{isPermissionsConsentNeeded: true, params}
-- HMI->SDL: GetUserFriendlyMessage{params},
-- SDL->HMI: GetUserFriendlyMessage_response{params}
-- HMI->SDL: GetListOfPermissions{appID}
-- SDL->HMI: GetListOfPermissions_response{}
-- b) HMI->SDL: OnAppPermissionConsent {params}
-- PoliciesManager: update "<appID>" subsection of "user_consent_records" subsection of "<device_identifier>" section of "device_data" section in Local PT.
-- c) SDL responds SUCCESS to allowed by USER RPC and DISALLOW to disallowed by Policy RPC.
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_connect_device.lua")
--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Local variables ]]
local RPC_Permission_for_1234567 = {}

--[[ Local Functions ]]
local function Get_RPCs()
  --Permission_for_1234567
  testCasesForPolicyTableSnapshot:extract_pts()

  for i = 1, #testCasesForPolicyTableSnapshot.pts_elements do

    if ( string.sub(testCasesForPolicyTableSnapshot.pts_elements[i].name,1,string.len("functional_groupings.Permission_for_1234567.rpcs.")) == "functional_groupings.Permission_for_1234567.rpcs." ) then
      local str = string.match(testCasesForPolicyTableSnapshot.pts_elements[i].name, "functional_groupings%.Permission_for_1234567%.rpcs%.(%S+)%.%S+%.%S+")
      if(#RPC_Permission_for_1234567 == 0) then
        RPC_Permission_for_1234567[#RPC_Permission_for_1234567 + 1] = str
      end

      if(RPC_Permission_for_1234567[#RPC_Permission_for_1234567] ~= str) then
        RPC_Permission_for_1234567[#RPC_Permission_for_1234567 + 1] = str
        -- allowed_rps[#allowed_rps + 1] = str
      end
    end
  end

end

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_connect_device')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_Connect_device()
  local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", {
      deviceList = { { id = config.deviceMAC, name = ServerAddress, transportType = "WIFI", isSDLAllowed = false} } })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function Test:Precondition_StartNewSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Precondition_Activate_App_And_Consent_Device()

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
          name = "127.0.0.1",
          id = config.deviceMAC,
          transportType = "WIFI",
          isSDLAllowed = false
        }
      }
    })
  :Do(function(_,data)
      self.applications["SPT"] = data.params.application.appID

      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["SPT"]})
      EXPECT_HMIRESPONSE(RequestId, { result = {
            code = 0,
            isSDLAllowed = false},
          method = "SDL.ActivateApp"})
      :Do(function(_,_)
          local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
          EXPECT_HMIRESPONSE(RequestId1,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          :Do(function(_,_)
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
              :Do(function(_,data1)
                  self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
                  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
                end)
            end)
        end)
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
end

function Test:Precondition_DeactivateApp()
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["SPT"], reason = "GENERAL"})
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "LIMITED"})
end

function Test:Precondition_UpdatePolicyWithPTU()
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
            }, "files/PTU_with_permissions_for_app_1234567.json")
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
            end)
        end)
    end)
end

--[[ Test ]]
function Test:TestStep_User_Consents_New_Permissions_After_App_Activation()
  Get_RPCs()
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

function Test:TestStep_Check_Allowed_RPC()

  local CorIdRAI = self.mobileSession:SendRPC("Show",
    {
      mediaClock = "00:00:01",
      mainField1 = "Show1"
    })
  EXPECT_HMICALL("UI.Show", {}):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, "UI.Show", "SUCCESS", { })
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
end

function Test:TestStep_Check_Disallowed_RPC()
  local cid = self.mobileSession:SendRPC("AddSubMenu",
    {
      menuID = 1000,
      position = 500,
      menuName ="SubMenupositive"
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end
