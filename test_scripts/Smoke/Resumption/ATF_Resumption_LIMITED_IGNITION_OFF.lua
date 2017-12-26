--  Requirement summary:
--  [HMILevel Resumption]: Send BC.OnResumeAudioSource to HMI for the app resumed to LIMITED
--  [HMILevel Resumption]: Conditions to resume app to LIMITED in the next ignition cycle
--
--  Description:
--  Any application in LIMITED HMILevel during the time frame of 30 sec (inclusive) before
--  BC.OnExitAllApplications(SUSPEND) from HMI
--  SDL must resume LIMITED level, send OnResumeAudioSource to each application.
--
--  1. Used preconditions
--  App is registered and activated on HMI

--  2. Performed steps
--  Perform iginition off
--  Perform ignition on
--
--  Expected result:
--  1. SDL sends to HMI OnSDLClose
--  2. App is registered, SDL sends OnAppRegistered with the same HMI appID as in last ignition cycle, then sets App to LIMITED HMI level
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

-- [[Local variables]]
local default_app_params = config.application1.registerAppInterfaceParams

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
            commonSteps:ActivateAppInSpecificLevel(self,
              self.applications[default_app_params.appName])
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
          end)
        end)
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("App resume at LIMITED level")
commonSteps:ChangeHMIToLimited()

function Test:IGNITION_OFF()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(function()
    self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
      { reason = "IGNITION_OFF" })
    EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
  end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
      SDL:DeleteFile()
      SDL:StopSDL()
    end)
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

function Test:Register_And_Resume_App_LIMITED()
  local mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobileSession:StartRPC()
  on_rpc_service_started:Do(function()
    default_app_params.hashID = self.currentHashID
    commonStepsResumption:RegisterApp(default_app_params, commonStepsResumption.ExpectResumeAppLIMITED, false)
  end)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test
