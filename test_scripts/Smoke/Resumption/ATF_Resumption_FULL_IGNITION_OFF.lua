--  Requirement summary:
--  [HMILevel Resumption]: Send BC.ActivateApp to HMI for the app resumed to FULLs
--  [HMILevel Resumption]: Conditions to resume app to FULL in the next ignition cycle
--
--  Description:
--  Any application that is the last one in FULL HMILevel
--  and it registers during 30 sec after BC.OnReady from HMI in the very next ignition cycle
--  SDL must resume FULL level of this application.
--
--  1. Used preconditions
--  App is registered and activated on HMI
--
--  2. Performed steps
--  Perform iginition off
--  Perform ignition on
--
--  Expected behavior:
--  1. SDL sends to HMI OnSDLClose
--  2. App is registered, SDL sends OnAppRegistered with the same HMI appID as in last ignition cycle,
--     then sends BasicCommunication.ActivateApp to HMI and after success response from HMI, SDL sends to App OnHMIStatus(FULL)
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
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

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

function Test:Start_SDL_With_One_Activated_App()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
          self:startSession():Do(function ()
            commonFunctions:userPrint(35, "App is registered")
            default_app = self.applications[default_app_params.appName]
            commonSteps:ActivateAppInSpecificLevel(self, default_app)
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL",audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            commonFunctions:userPrint(35, "App is activated")
          end)
        end)
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("App resume at FULL level")

function Test:IGNITION_OFF()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(function()
    self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
      { reason = "IGNITION_OFF" })
    EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
  end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  SDL:DeleteFile()
end

function Test:Restart_SDL_And_Add_Mobile_Connection()
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

function Test:Register_And_Resume_App_FULL()
  local mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobileSession:StartRPC()
  on_rpc_service_started:Do(function()
    default_app_params.hashID = self.currentHashID
    commonStepsResumption:RegisterApp(default_app_params, commonStepsResumption.ExpectResumeAppFULL, false)
  end)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test