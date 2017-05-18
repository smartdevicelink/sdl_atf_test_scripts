---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Policy Table Update in case of failed retry strategy during previous IGN_ON
-- [HMI API] PolicyUpdate request/response

-- Description:
-- SDL should request in case of failed retry strategy during previour IGN_ON
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Connect mobile phone over WiFi.
-- Register new application.
-- Successful PTU.
-- Register new application.
-- PTU is requested.
-- IGN OFF
-- 2. Performed steps
-- IGN ON.
-- Connect device. Application is registered.
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ Local Variables ]]
local hmi_app_id1, hmi_app_id2

--[[ General Precondition before ATF start ]]
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")  

function Test:Precondition_HTTP_Successful_Flow ()
  commonFunctions:check_ptu_sequence_partly(self, "files/ptu_general.json", "ptu_general.json")
end

function Test:Precondition_StartNewSession()
  self.mobileSession1 = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:Precondition_RegisterNewApplication()
  hmi_app_id1 = self.applications[config.application1.registerAppInterfaceParams.appName]
  local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
   EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName } })
  :Do(function(_,_data2)
      hmi_app_id2 = _data2.params.application.appID

      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"})

      testCasesForPolicyTableSnapshot:verify_PTS(true,
        {config.application1.registerAppInterfaceParams.appID, config.application2.registerAppInterfaceParams.appID},
        {config.deviceMAC},
        {hmi_app_id1, hmi_app_id2})

      local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
      local seconds_between_retries = {}
      for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
        seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
      end
     end)
  self.mobileSession1:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
end

function Test:Precondition_Suspend()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
end

function Test:Precondition_IGNITION_OFF()
  StopSDL()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered"):Times(2)
end

function Test:Precondtion_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash, self)
end

function Test:Precondtion_initHMI()
  self:initHMI()
end

function Test:Precondtion_initHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondtion_ConnectMobile()
  self:connectMobile()
end

function Test:Precondtion_CreateSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

-- [[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU_NotSuccessful_AppID_ListedPT_NewIgnCycle()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
   EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.appName } })
  :Do(function(_,_)
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"})

      testCasesForPolicyTableSnapshot:verify_PTS(true,
        {config.application1.registerAppInterfaceParams.appID, config.application2.registerAppInterfaceParams.appID},
        {config.deviceMAC},
        {hmi_app_id1, hmi_app_id2})

      local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
      local seconds_between_retries = {}
      for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
        seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
      end
    end)

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test