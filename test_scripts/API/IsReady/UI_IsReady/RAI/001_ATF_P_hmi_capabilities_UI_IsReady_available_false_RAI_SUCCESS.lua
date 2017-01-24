---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] SDL behavior in case <Interface> is not supported by system
-- [UI Interface] UI.IsReady(false) -> HMI respond with successfull resultCode to splitted RPC
-- [HMI_API] UI.IsReady
--
-- Description:
-- In case HMI respond UI.IsReady (<successfull_resultCode>, available=false) to SDL
-- and mobile app sends RegisterAppInterface_request to SDL and SDL successfully registers this application
-- SDL must: omit UI-related param from response to mobile app (meaning: SDL must NOT retrieve the default
-- values from 'HMI_capabilities.json' file and provide via response to mobile app)
--
-- 1. Used preconditions
-- In InitHMIOnReady send UI.IsReady(available = false)
-- GetCapabilities is not invoked at system start-up as UI is not supported
--
-- 2. Performed steps
-- Register new application with resultcode = SUCCESS
--
-- Expected result:
-- SDL->mobile: RegisterAppInterface_response steeringWeelLocation is omitted
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForRAI = require('user_modules/shared_testcases/testCasesForRAI')
local events = require("events")
local mobile_session = require('mobile_session')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_initHMI')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_InitHMI_OnReady()
	testCasesForRAI.InitHMI_onReady_without_UI_IsReady_GetCapabilities(self)
	
  EXPECT_HMICALL("UI.IsReady")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {available = false})
  end)

	EXPECT_HMICALL("UI.GetCapabilities"):Times(0):Timeout(20000)
  commonTestCases:DelayedExp(20000)
end

function Test:Precondition_connectMobile()
	self:connectMobile()
end

function Test:Precondition_StartSession()
	self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
	self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_RAI_SUCCESS_IsReady_available_false()
	local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
	EXPECT_RESPONSE(CorIdRegister, { success=true, resultCode = "SUCCESS" })
  :ValidIf(function(_,data)
    if( data.payload.hmiCapabilities )then
      commonFunctions:printError("hmiCapabilities is sent by SDL when IsReady (available = false)")
      return false
    else
      return true
    end
  end)
	EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop()
  StopSDL()
end

return Test