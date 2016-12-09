-- UNREADY - Securuty is not implemented in ATF

-- Requirement summary:
-- In case
-- SDL starts PolicyTableUpdate in case of no "certificate" at "module_config" section at LocalPT (please see APPLINK-27521, APPLINK-27522)
-- and PolicyTableUpdate is failed by any reason even after retry strategy (please see related req-s HTTP flow and Proprietary flow)
-- and "ForceProtectedService" is ON at .ini file
-- and app sends StartService (<any_serviceType>, encypted=true) to SDL
-- SDL must:
-- respond StartService (NACK, encrypted=true) to this mobile app
-- Preconditions:
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
---------------------------------------------------------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Local functions]]
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
  appID = "MyTestApp",
  deviceInfo =
  {
    os = "Android",
    carrier = "Megafon",
    firmwareRev = "Name: Linux, Version: 3.4.0-perf",
    osVersion = "4.4.2",
    maxNumberRFCOMMPorts = 1
  }
}

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
Test["UpdateForceProtectedService_" .. tostring("prefix")] = function()
  commonFunctions:SetValuesInIniFile("%p?ForceProtectedService%s?=%s-[%w%d,-]-%s-\n", "ForceProtectedService", "ON" )
end

Test["StopSDL"] = function()
  StopSDL()
end

function Test:Precondition_StartSDL_NextLifeCycle()
  -- self should be comment before run
  self()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_InitHMI_NextLifeCycle()
  self:initHMI()
end

function Test:Precondition_InitHMI_onReady_NextLifeCycle()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile_NextLifeCycle()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:Precondition_RAI_NewSession()
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:UpdatePolicyWithWrongPTU()
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {url = "http://policies.telematics.ford.com/api/policies"}}})
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "ptu.json"
        },
        "/tmp/fs/mp/images/ivsu_cache/"
      )
    end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
end

function Test:Start_Secure_Service()
  -- self should be comment before run
  self()
  print("Starting security service is not implemented")
  EXPECT_HMICALL("SDL.PolicyUpdate")
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}):Timeout(500)
end

--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test:Postcondition_SDLForceStop()
  commonFunctions:SDLForceStop(self)
end
