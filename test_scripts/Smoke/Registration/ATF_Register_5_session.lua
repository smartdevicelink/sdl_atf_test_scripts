--  Requirement summary:
--  [RegisterAppInterface] SUCCESS
--  [RegisterAppInterface] RegisterAppInterface and HMILevel
--
--  Description:
--  Check that it is able to register 5 sessions within 1 phisycal connection.
--  Sessions have to be added one by one.
--
--  1. Used precondition
--  SDL, HMI are running on system.
--  Mobile device is connected to system.
--  1 session is added, 1 app is registered.
--
--  2. Performed steps
--  Add 2 session
--  appID_2->RegisterAppInterface(params)
--  Add 3 session
--  appID_3->RegisterAppInterface(params)
--  Add 4 session
--  appID_4->RegisterAppInterface(params)
--  Add 5 session
--  appID_5->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL successfully registers all four applications and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--  2. SDL assignes HMILevel after application registering:
--     SDL->appID: OnHMIStatus(HMlLevel, audioStreamingState, systemContext)
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- [[Local variables]]
local default_app_params2 = config.application2.registerAppInterfaceParams
local default_app_params3 = config.application3.registerAppInterfaceParams
local default_app_params4 = config.application4.registerAppInterfaceParams
local default_app_params5 = config.application5.registerAppInterfaceParams

--[[ Local Functions ]]
local function startSessionAndRegisterApp(self, app)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartRPC():Do(function()
    local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", app)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = app.appName}})
    self.mobileSession:ExpectResponse(correlation_id, {success = true, resultCode = "SUCCESS"})
    self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    self.mobileSession:ExpectNotification("OnPermissionsChange", {})
  end)
end

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
            commonFunctions:userPrint(35, "1st App is successfully registered")
          end)
        end)
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Start_Session2_And_Register_App_2()
  startSessionAndRegisterApp(self, default_app_params2)
end

function Test:Start_Session3_And_Register_App_3()
  startSessionAndRegisterApp(self, default_app_params3)
end

function Test:Start_Session4_And_Register_App_4()
  startSessionAndRegisterApp(self, default_app_params4)
end

function Test:Start_Session5_And_Register_App_5()
  startSessionAndRegisterApp(self, default_app_params5)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test