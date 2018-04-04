---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: SDL.OnPolicyUpdate initiation of PTU
-- [HMI API] SDL.OnPolicyUpdate notification
--
-- Description:
-- 1. Used preconditions: SDL and HMI are running, Device connected to SDL is consented by the User, App is running on this device, and registerd on SDL
-- 2. Performed steps: HMI->SDL: SDL.OnPolicyUpdate
--
-- Expected result:
-- SDL->HMI: BasicCommunication.PolicyUpdate
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
function Test:Precondtion_connectMobile()
  self:connectMobile()
end

function Test:Precondtion_CreateSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:Precondtion_Activate_App_Consent_Update()
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
          transportType = "WIFI",
          isSDLAllowed = false
        }
      }
    })
  :Do(function(_,data)
      local RequestIdActivateApp = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = data.params.application.appID})
      EXPECT_HMIRESPONSE(RequestIdActivateApp, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
      :Do(function(_,_)
          local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
          EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          :Do(function(_,_)
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
              :Do(function(_,data1)
                  self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
                  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
                end)
            end)
        end)
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,_)
      local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
      EXPECT_HMIRESPONSE(RequestIdGetURLS)
      :Do(function()
          self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{requestType = "PROPRIETARY", fileName = "filename"})
          EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
          :Do(function()
              local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/ptu_general.json")
              local systemRequestId
              EXPECT_HMICALL("BasicCommunication.SystemRequest")
              :Do(function(_,data)
                  systemRequestId = data.id
                  self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                    {
                      policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                    })
                  local function to_run()
                    self.hmiConnection:SendResponse(systemRequestId, "BasicCommunication.SystemRequest", "SUCCESS", {})
                    self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
                  end
                  RUN_AFTER(to_run, 800)
                  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}):Timeout(500)
                end)
            end)
        end)
    end)
end

--[[ Test ]]
function Test:TestStep_Send_OnPolicyUpdate_from_HMI()
  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate")
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
end

--[[ Postconditions ]]
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
