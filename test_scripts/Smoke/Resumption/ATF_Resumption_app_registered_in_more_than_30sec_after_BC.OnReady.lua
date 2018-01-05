--  Requirement summary:
--  [HMILevel Resumption]: Conditions to resume app to FULL in the next ignition cycle
--
--  Description:
--  Check that SDL does not perform App resumption in case when app is
--  registered in more than 30 sec. after BC.OnReady from HMI in the very next ignition cycle
--
--  1. Used precondition
--  Media App is registered and active on HMI
--
--  2. Performed steps
--  Send IGNITION_OFF from HMI.
--  Start SDL.
--  Wait 30 seconds and turn on transport.
--
--  Expected behavior:
--  1. SDL sends to HMI OnSDLClose.
--     App is registered successfully and get default HMI level.
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

--[[ Test ]]
commonFunctions:newTestCasesGroup("SDL does not perform App resumption when app is registered in more than 30 sec after BC.OnReady")

function Test:IGNITION_OFF()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete"):Do(function()
    SDL:DeleteFile()
    self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
      { reason = "IGNITION_OFF" })
    EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
  end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
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

function Test.Sleep_31_sec()
  os.execute("sleep " .. 31)
end

function Test:Register_And_No_Resume_App()
  local mobile_session1 = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobile_session1:StartRPC()
  on_rpc_service_started:Do(function()
    commonStepsResumption:RegisterApp(default_app_params, commonStepsResumption.ExpectNoResumeApp, false)
  end)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test
