---------------------------------------------------------------------------------------------
-- Description:
-- Application with appID intends to be registered on SDL, device with deviceID the application is running on is connected to HU.
-- 1. Used preconditions:
-- Restart SDL and clean all data to set SDL in first life cycle state.
-- 2. Performed steps
-- Register new application.
--
-- Requirement summary:
-- The order of requests/responses/notifications during application registering must be the following:
-- 1. app->SDL: RegisterAppInterface (policy_appID, parameters)
-- 2. SDL->HMI: OnAppRegistered (hmi_appID, params)
-- 3. SDL->app: RegisterAppInterface_response (<applicable resultCode>, success:true)
-- 4. SDL->app: OnHMIStatus(hmiLevel,audioStreamingState, systemContext)
-- 5. SDL->app: OnPermissionsChange(params)
--
-- Expected result:
-- 1. On performing all checks for successful registering SDL notifies HMI about registering before sending a response to mobile application:
-- SDL->HMI: OnAppRegistered(hmi_appID)
-- 2. SDL->appID: (<applicable resultCode>, success:true): RegisterAppInterface()
-- 3. On registering the application, HMIStatus parameters are assinged to the application:
-- SDL->app: OnHMIStatus(hmiLevel,audioStreamingState, systemContext)
-- 4. SDL assigns the appropriate policies and notifies application:
-- SDL->app: OnPermissionsChange (params) - as specified in "pre_DataConsent" section.
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
local function Precondition()

  commonFunctions:userPrint(34, "-- Precondition --")

  function Test:StopSDL()
    StopSDL()
  end

  --ToDo: shall be removed when issue: "SDL doesn't stop at execution ATF function StopSDL()" is fixed
  function Test:SDLForceStop()
    commonFunctions:SDLForceStop()
  end

  function Test:DeleteLogsAndPolicyTable()
    commonSteps:DeleteLogsFiles()
    commonSteps:DeletePolicyTable()
  end

  function Test:StartSDL_FirstLifeCycle()
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI_FirstLifeCycle()
    self:initHMI()
  end

  function Test:InitHMI_onReady_FirstLifeCycle()
    self:initHMI_onReady()
  end

  function Test:ConnectMobile_FirstLifeCycle()
    self:connectMobile()
  end

  function Test:StartSession()
    self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
    self.mobileSession:StartService(7)
  end

end

Precondition()

--[[ Test ]]
function Test:Register_App_And_Check_Order_Of_Request_Response_Notiofications()
  commonFunctions:userPrint(34, "-- Test --")
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
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  EXPECT_NOTIFICATION("OnPermissionsChange", {})
end

--[[ Postconditions ]]
--ToDo: shall be removed when issue: "SDL doesn't stop at execution ATF function StopSDL()" is fixed
function Test:SDLForceStop()
  commonFunctions:userPrint(34, "-- Postcondition --")
  commonFunctions:SDLForceStop()
end
