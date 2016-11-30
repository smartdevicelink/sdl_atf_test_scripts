-- UNREADY:
-- Hello Iliyana, in this script I couldn't receive respond to SDL.GetURLs request from HMI with this url http://policies.url.com. As I understand move system
-- in UP_TO_DATE state should be also with the same url?
--
-- Note: Added "http://policies.url.com" in sdl_preloaded and ptu.json
-- Requirement summary:
-- [PTU-Proprietary] Respond to SDL.GetURLs request from HMI
--
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
-- Description:
-- respond SDL.GetURLs_response (SUCCESS, urls: array(<SDL-chosen appID> + <url from policy database for service 7>)) to HMI
-- 1. Used preconditions: SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
--
-- Performed steps
-- 1. Move state of system in UP_TO_DATE
-- 2. hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
--
-- Expected result:
-- respond SDL.GetURLs_response (SUCCESS, urls: array(<SDL-chosen appID> + <url from policy database for service 7>)) to HMI

---------------------------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')

--[[ Local Variables ]]
--NewTestSuiteNumber = 0

--[[ General Precondition before ATF start]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')

--[[ Local Variables ]]
local registerAppInterfaceParams =
{
  syncMsgVersion =
  {
    majorVersion = 3,
    minorVersion = 0
  },
  appName = "Media Application",
  isMediaApplication = true,
  languageDesired = 'EN-US',
  hmiDisplayLanguageDesired = 'EN-US',
  appHMIType = {"NAVIGATION"},
  appID = "MyApp",
  deviceInfo =
  {
    os = "Android",
    carrier = "Megafon",
    firmwareRev = "Name: Linux, Version: 3.4.0-perf",
    osVersion = "4.4.2",
    maxNumberRFCOMMPorts = 1
  }
}

--[[ Local Functions ]]
local function policyUpdate(self)
  local pathToSnaphot = nil
  EXPECT_HMICALL ("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      pathToSnaphot = data.params.file
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.PolicyUpdate", "SUCCESS", {})
    end)
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {url = "http://policies.url.com"}}})
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          url = "http://policies.url.com",
          appID = self.applications ["Test Application"],
          fileName = "sdl_snapshot.json"
        },
        pathToSnaphot
      )
    end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
  :Do(function(_,_)
      local CorIdSystemRequest = self.mobileSession:SendRPC ("SystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "sdl_snapshot.json"
        },
        pathToSnaphot
      )
      EXPECT_HMICALL("BasicCommunication.SystemRequest")

      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
        end)
      EXPECT_RESPONSE(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
            {
              policyfile = "/tmp/fs/mp/images/ivsu_cache/ptu.json"
            })
        end)
      :Do(function(_,_)
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_MoveSystem_UP_TO_DATE()
  policyUpdate(self, "/tmp/fs/mp/images/ivsu_cache/ptu.json")
end

function Test:Precondition_OpenNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:Precondition_RAI_NewSession()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
-- function Test:TestStep_Respond_SDL_GetURLs_from_HMI()
-- local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
-- --SDL.GetURLs_response (SUCCESS, urls: array(<SDL-chosen appID> + <url from policy database for service 7>))
-- EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = "SUCCESS", method = "SDL.GetURLS", urls = {url = "http://policies.url.com"}}})
-- end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
Test["StopSDL"] = function()
  StopSDL()
end
