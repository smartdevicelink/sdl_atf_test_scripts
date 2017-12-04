--  Requirement summary:
--  [HMILevel Resumption]: Conditions to resume app to LIMITED after "unexpected disconnect" event.
--
--  Description:
--  Check that SDL resumes LIMITED  level of media App and it's data
--  after transport unexpected disconnect

--  1. Used precondition
--  App in LIMITED on HMI.
--  App has added 1 sub menu, 1 command and 1 choice set.
--
--  2. Performed steps
--   Turn off transport.
--   Turn on transport.
--
--  Expected behavior:
--  1. App is unregistered from HMI.
--  2. App is registered on HMI, SDL resumes all App's data and sends OnResumeAudioSource to HMI.
--     App gets LIMITED HMI Level
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.isMediaApplication = true

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonStepsResumption = require('user_modules/shared_testcases/commonStepsResumption')
local mobile_session = require('mobile_session')

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
            commonFunctions:userPrint(35, "App is registered")
            commonSteps:ActivateAppInSpecificLevel(self, self.applications[default_app_params.appName])
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
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
commonFunctions:newTestCasesGroup("Transport unexpected disconnect. App resume at LIMITED level")
commonSteps:ChangeHMIToLimited("Change_app_to_Limited")

function Test:Close_Session()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true,
                   appID = self.applications[default_app_params]})
  self.mobileSession:Stop()
end

function Test:Register_And_Resumes_App_And_Data()
  local mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobileSession:StartRPC()
  on_rpc_service_started:Do(function()
    default_app_params.hashID = self.currentHashID
    commonStepsResumption:Expect_Resumption_Data(default_app_params)
    commonStepsResumption:RegisterApp(default_app_params, commonStepsResumption.ExpectResumeAppLIMITED, true)
  end)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test