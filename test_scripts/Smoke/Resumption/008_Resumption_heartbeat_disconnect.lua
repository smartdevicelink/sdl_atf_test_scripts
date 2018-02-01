--  Requirement summary:
--  [Data Resumption]: Data resumption on Unexpected Disconnect
--
--  Description:
--  Check that SDL perform resumption after heartbeat disconnect.

--  1. Used precondition
--  In smartDeviceLink.ini file HeartBeatTimeout parameter is:
--  HeartBeatTimeout = 7000.
--  App is registerer and activated on HMI.
--  App has added 1 sub menu, 1 command and 1 choice set.
--
--  2. Performed steps
--  Wait 20 seconds.
--  Register App with hashId.
--
--  Expected behavior:
--  1. SDL sends OnAppUnregistered to HMI.
--  2. App is registered and  SDL resumes all App data, sends BC.ActivateApp to HMI, app gets FULL HMI level.
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 3
config.application1.registerAppInterfaceParams.isMediaApplication = true

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonStepsResumption = require('user_modules/shared_testcases/commonStepsResumption')
local mobile_session = require('mobile_session')
local events = require("events")

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- [[Local variables]]
local default_app_params = config.application1.registerAppInterfaceParams

-- [[Local functions]]
local function connectMobile(self)
  self.mobileConnection:Connect()
  return EXPECT_EVENT(events.connectedEvent, "Connected")
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

function Test:StartSDL_With_One_Activated_App()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        connectMobile(self):Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
          self:startSession():Do(function ()
            commonFunctions:userPrint(35, "App is registered")
            commonSteps:ActivateAppInSpecificLevel(self, self.applications[default_app_params.appName])
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL",audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            commonFunctions:userPrint(35, "App is activated")
          end)
        end)
      end)
    end)
  end)
end

function Test.AddCommand()
  commonStepsResumption:AddCommand()
end

function Test.AddSubMenu()
  commonStepsResumption:AddSubMenu()
end

function Test.AddChoiceSet()
  commonStepsResumption:AddChoiceSet()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Check that SDL perform resumption after heartbeat disconnect")

function Test:Wait_20_sec()
  self.mobileSession:StopHeartbeat()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[default_app_params], unexpectedDisconnect = true })
  :Timeout(20000)
  EXPECT_EVENT(events.disconnectedEvent, "Disconnected")
  :Do(function()
      print("Disconnected!!!")
    end)
  :Timeout(20000)
end

function Test:Connect_Mobile()
  connectMobile(self)
end

function Test:Register_And_Resume_App_And_Data()
  local mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobileSession:StartRPC()
  on_rpc_service_started:Do(function()
    default_app_params.hashID = self.currentHashID
    commonStepsResumption:Expect_Resumption_Data(default_app_params)
    commonStepsResumption:RegisterApp(default_app_params, commonStepsResumption.ExpectResumeAppFULL, true)
  end)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test
