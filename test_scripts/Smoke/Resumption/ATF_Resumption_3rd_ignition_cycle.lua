--  Requirement summary:
--  [Data Resumption]: Data resumption on IGNITION OFF
--  [HMILevel Resumption]: Conditions to resume app to FULL in the next ignition cycle.

--  Description:
--  Check that:
--  1. SDL performs App data resumption in case when media app tries to resume in 3rd ignition cycle.
--  2. SDL doesn't resumes App to FULL hmi level.
--
--  1. Used precondition
--  Media App is registered and active on HMI
--
--  2. Performed steps
--  Send IGNITION_OFF from HMI.
--  Start SDL. (2nd ignition cycle)
--  Send IGNITION_OFF from HMI.
--  Start SDL. (3rd ignition cycle)
--  Connect transport.
--
--  Expected behavior:
--  1. In 3rd ignition cycle App is registered and get default HMI level, app data is resumed.
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.isMediaApplication = true

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonStepsResumption = require('user_modules/shared_testcases/commonStepsResumption')
local mobile_session = require('mobile_session')
local SDL = require('SDL')

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- [[ Local variables]]
local default_app_params = config.application1.registerAppInterfaceParams
local default_app = nil -- will be initialized after application registration

-- [[ Local Functions ]]
local function Start_SDL_And_Add_Mobile_Connection()
  Test:runSDL()
  commonFunctions:waitForSDLStart(Test):Do(function()
    Test:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      Test:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        Test:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
        end)
      end)
    end)
  end)
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

function Test.Start_SDL_Add_Mobile_Connection()
  Start_SDL_And_Add_Mobile_Connection()
end

function Test:Start_Session_And_Register_App()
  self:startSession():Do(function()
    commonFunctions:userPrint(35, "App is registered")
    default_app = self.applications[default_app_params.appName]
    commonSteps:ActivateAppInSpecificLevel(self, default_app)
    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL",audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    commonFunctions:userPrint(35, "App is activated")
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
commonFunctions:newTestCasesGroup("SDL should perform data resumption application is registered within 3 ign cycles")

function Test.IGNITION_OFF()
  Test.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(function()
    Test.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
      { reason = "IGNITION_OFF" })
    EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
    SDL:DeleteFile()
  end)
end

function Test.Restart_SDL_And_Add_Mobile_Connection()
  Start_SDL_And_Add_Mobile_Connection()
end

function Test.IGNITION_OFF()
  Test.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(function()
    Test.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
      { reason = "IGNITION_OFF" })
    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
    SDL:DeleteFile()
  end)
end

function Test.Restart_SDL_And_Add_Mobile_Connection()
  Start_SDL_And_Add_Mobile_Connection()
end

function Test:Register_And_No_Resume_App()
  local mobile_session1 = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobile_session1:StartRPC()
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