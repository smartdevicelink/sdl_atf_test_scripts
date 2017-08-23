--  Requirement summary:
--  [HMILevel Resumption]: Both LIMITED and FULL applications must be included to resumption list
--
--  Description:
--  Applications of BACKGROUND are not the case of HMILevel resumption in the next ignition cycle.
--  Check that SDL performs app's data resumption and does not resume BACKGROUND HMI level
--  of media after transport unexpected disconnect on mobile side.

--  1.  Used precondition
--  App in  BACKGROUND
--  Default HMI level is NONE.
--  App has added 1 sub menu, 1 command and 1 choice set.

--  2. Performed steps
--  Turn off transport.
--  Turn on transport.
--
--  Expected behavior:
--  1. App is unregistered from HMI.
--     App is registered on HMI, SDL resumes all data and App gets default HMI level NONE.
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.isMediaApplication = true

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
local default_app_params1 = config.application1.registerAppInterfaceParams
local default_app_params2 = config.application2.registerAppInterfaceParams

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
            commonSteps:ActivateAppInSpecificLevel(self, self.applications[default_app_params1.appName])
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
commonFunctions:newTestCasesGroup("Transport unexpected disconnect. Media app not resume at BACKGROUND level")
commonSteps:precondition_AddNewSession()
commonSteps:RegisterTheSecondMediaApp()
commonSteps:ActivateTheSecondMediaApp()

function Test:Close_Session2()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true,
    appID = self.applications[default_app_params2.appName]})
  self.mobileSession2:Stop()
end

function Test:Close_Session1()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true,
    appID = self.applications[default_app_params1.appName]})
  self.mobileSession:Stop()
end

function Test:Register_And_No_Resume_App_BACKGROUND_And_Resumes_Data()
  local mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobileSession:StartRPC()
  default_app_params1.hashID = self.currentHashID
  on_rpc_service_started:Do(function()
    commonStepsResumption:Expect_Resumption_Data(default_app_params1)
    commonStepsResumption:RegisterApp(default_app_params1, commonStepsResumption.ExpectNoResumeApp, true)
  end)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test
