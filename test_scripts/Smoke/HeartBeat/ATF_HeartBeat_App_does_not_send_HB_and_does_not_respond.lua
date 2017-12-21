--  Requirement summary:
--  [HeartBeat]: SDL must close only session in case mobile app does not answer on Heartbeat_request
--  [HeartBeat] [GENIVI]: SDL must start HeartBeat process immediately after first StartService request from mobile app
--
--  Description:
--  Check that heartbeat timeout occurs if App uses v3 protocol version and doesn't send HB to SDL
--  and doesn't response to SDL HB

--  1. Used precondition
--  SDL, HMI are running.
--  Mobile device is connected.
--  HeartBeatTimeout = 5000
--
--  2. Performed steps
--  Start SPT, select transport, specify protocols = 3
--  sendHeartbeatToSDL = false
--  answerHeartbeatFromSDL = false
--  Wait 15 sec.
--
--  Expected behavior:
--  1. App has successfully registered.
--  2. App is disconnected by SDL due to heartbeat timeout occurs.
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 3
config.application1.registerAppInterfaceParams.isMediaApplication = true

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local mobile_session = require('mobile_session')

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- [[Local variables]]
local default_app_params = config.application1.registerAppInterfaceParams
local default_app_params2 = config.application2.registerAppInterfaceParams

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()
commonPreconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("HeartBeatTimeout", 5000)

function Test:StartSDL_And_Connect_Mobile()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
        end)
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Start_Session_And_Register_App()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession.activateHeartbeat = false
  self.mobileSession.sendHeartbeatToSDL = false
  self.mobileSession.answerHeartbeatFromSDL = false
  self.mobileSession.ignoreSDLHeartBeatACK = false
  self.mobileSession:StartRPC():Do(function()
    local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", default_app_params)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      { application = { appName = default_app_params.appName}}):Do(function(_,data)
      default_app_params.hmi_app_id = data.params.application.appID
    end)
    self.mobileSession:ExpectResponse(correlation_id, {success = true, resultCode = "SUCCESS"})
    self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    self.mobileSession:ExpectNotification("OnPermissionsChange", {})
  end)
end

function Test:Register_Second_App_With_HeartBeat()
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession1.activateHeartbeat = true
  self.mobileSession1.sendHeartbeatToSDL = true
  self.mobileSession1.answerHeartbeatFromSDL = true
  self.mobileSession1.ignoreSDLHeartBeatACK = false
  self.mobileSession1:StartRPC():Do(function()
    local correlation_id = self.mobileSession1:SendRPC("RegisterAppInterface", default_app_params2)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = default_app_params2.appName}})
    self.mobileSession1:ExpectResponse(correlation_id, {success = true, resultCode = "SUCCESS"})
    self.mobileSession1:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    self.mobileSession1:ExpectNotification("OnPermissionsChange", {})
  end)
end

function Test:Wait_15_seconds_And_Verify_OnAppUnregistered()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = default_app_params.hmi_app_id, unexpectedDisconnect =  true}):Timeout(15000):Do(function()
    self.mobileSession:StopHeartbeat()
  end)
end

function Test:Verify_That_Second_App_Still_Registered()
  local cor_id = self.mobileSession1:SendRPC("RegisterAppInterface", default_app_params2)
  self.mobileSession1:ExpectResponse(cor_id, { success = false, resultCode = "APPLICATION_REGISTERED_ALREADY"})
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
  StopSDL()
end

return Test
