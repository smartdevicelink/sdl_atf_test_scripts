-- Requirement summary:
-- [PolicyTableUpdate] Policy Table Update in case of failed retry strategy during previous IGN_ON
-- [HMI API] OnStatusUpdate
--
-- Description:
-- PoliciesManager must check the stored status of PTUpdate upon every Ign_On and IN CASE the status is UPDATE_NEEDED
-- PoliciesManager must initiate the PTUpdate sequence right after the first app registers on SDL
-- 1. Used preconditions: device and app with app_ID is running the application is not yet connected to SDL
-- the status of PTU Update is UPDATE_NEEDED
-- 2. Performed steps: IGN_ON happens
--
-- Expected result:
-- 1. PolicyManager checks the status of PTU Update
-- 2. On application with app_ID registering :
-- 2.1. app_ID->SDL:RegisterAppInterface()
-- 2.2. SDL->app_ID:SUCCESS:RegisterAppInterface()
-- 3. PTU sequence started: *SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)*
-- 4. PTS is created by SDL.....//PTU started
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = {"DEFAULT"}

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--TODO(VVVakulenko): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('modules/connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

---[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_SDLStop()
  StopSDL()
end

function Test.Precondition_DeleteLogsAndPolicyTable()
  commonSteps:DeleteLogsFiles()
  commonSteps:DeletePolicyTable()
end

function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_initHMI()
  self:initHMI()
end

function Test:Precondition_initHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:Precondition_CreateSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:RegisterApp()
  self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Suspend()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
end

function Test:TestStep_IGNITION_OFF()
  StopSDL()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
end

function Test.TestStep_startSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:TestStep_InitHMI()
  self:initHMI()
end

function Test:TestStep_InitHMI_onReady()
  self:initHMI_onReady()
end

function Test:TestStep_ConnectMobile()
  self:connectMobile()
end

function Test:TestStep_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:TestStep_RegisterApp_failed_retry_strategy_in_prev_IGN_cycle()
  --TODO(istoimenova): Remove when "[ATF] One and the Same CorrelationID is Sent for Two Sessions" is fixed.
  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.appName } })
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
