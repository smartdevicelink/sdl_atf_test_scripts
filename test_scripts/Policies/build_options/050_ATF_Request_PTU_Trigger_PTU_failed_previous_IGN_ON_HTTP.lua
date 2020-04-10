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
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.ExitOnCrash = false

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
Preconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("HMICapabilitiesCacheFile", "")

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
  local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, {status = "UPDATING"}):Times(2)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName } })
  self.mobileSession1:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
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
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, {status = "UPDATING"}):Times(2)
  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

function Test.RestoreIniFile()
  Preconditions:RestoreFile("smartDeviceLink.ini")
end

return Test
