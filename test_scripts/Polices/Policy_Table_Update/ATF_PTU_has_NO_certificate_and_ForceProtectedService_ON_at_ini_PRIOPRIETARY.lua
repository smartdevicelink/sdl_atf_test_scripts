-- UNREADY - Securuty is not implemented in ATF

---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU] [GENIVI] PolicyTableUpdate has NO "certificate" and "ForceProtectedService"=ON at .ini file
--
-- Description:
-- Describe correctly the CASE of requirement that is covered, conditions that will be used.
-- 1. Used preconditions: 
--    SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
--    "ForceProtectedService" is ON at .ini file
-- 2. Performed steps: 
-- SDL starts PolicyTableUpdate in case of no "certificate" at "module_config" section at LocalPT
-- PolicyTableUpdate bring NO "certificate" at "module_config" section
-- app sends StartService (<any_serviceType>, encypted=true) to SDL
--
-- Expected result:
-- SDL must respond StartService (NACK) to this mobile app
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')


--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
--ToDo(vvvakulenko): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_UpdateForceProtectedService_in_ini_file()
  commonFunctions:SetValuesInIniFile("%p?ForceProtectedService%s?=%s-[%w%d,-]-%s-\n", "ForceProtectedService", "ON" )
end

function Test.TestStep_StartSDLAfterStop()
  Test["StartSDL"] = function ()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  Test["TestInitHMI"] = function (self)
  self:initHMI()
  end

  Test["TestInitHMIOnReady"] = function (self)
  self:initHMI_onReady()
  end

  Test["ConnectMobile"] = function (self)
  self:connectMobile()
  end

  Test["StartSession"] = function (self)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test.TestStep_ActivateApp()
  commonSteps:ActivationApp()
end

function Test.TestStep_UpdatePolicyWithWrongPTU()
  policy:UpdatePolicyWithWrongPTU()
end

function Test.TestStep_Start_Secure_Service()
  print("Starting security service is not implemented")
  EXPECT_HMICALL("SDL.PolicyUpdate")
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test:Postcondition_Force_Stop_SDL()
  commonFunctions:SDLForceStop(self)
end

return Test