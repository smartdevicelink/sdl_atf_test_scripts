--UNREADY
-- clarification needed how to check expiration date if certificate against the cuttent date
---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU]: In case current date is "24 hours prior to module`s certificate expiration date"
-- [INI file] [Security Manager] UpdateBeforeHours
--
-- Description:
-- PoliciesManager must start a PolicyTable Update sequence IN CASE the current date is "24 hours prior to module's certificate expiration date"
-- 1. Used preconditions: 
--    SDL and HMI are started and running
--    Policies database exists with valid "certificate" in "module_config"
--    App is registered from consented devise
-- 2. Performed steps:
-- SDL: Check expiration date if certificate against the cuttent date
-- Current date is "24 hours prior to module's expiration date"
-- SDL: Start PT Exchange sequence
-- SDL->HMI: OnStatusUpdate("UPDATE_NEEDED"), then regular PTU sequence
--
-- Expected result:
-- if current date is "24 hours prior to module's expiration date"
-- SDL: Start PT Exchange sequence
-- SDL->HMI: OnStatusUpdate("UPDATE_NEEDED"), then regular PTU sequence
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
--local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
--local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForBuildingSDLPolicyFlag = require('user_modules/shared_testcases/testCasesForBuildingSDLPolicyFlag')
--local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
testCasesForBuildingSDLPolicyFlag:Update_PolicyFlag("EXTENDED_POLICY","")
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("EXTENDED_POLICY","")
commonSteps:DeleteLogsFileAndPolicyTable()

--TODO(VVVakulenko): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
require('user_modules/AppTypes')
require('mobile_session')

--[[ Preconditions ]]

commonFunctions:newTestCasesGroup("Preconditions")

commonSteps:DeleteLogsFileAndPolicyTable()

function Test:Precondition_RegisterApp_consented() 
  local corr_id = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
        self.HMIAppID = data.params.application.appID
      end)
  EXPECT_RESPONSE(corr_id, { success = true, resultCode = "SUCCESS"})
    :Do(function()      
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN"})
    end)
  EXPECT_NOTIFICATION("OnPermissionsChange")
end

--[[ Test ]]
function Test.TestStep_Check_exp_date_of_certificate_against_cuttent()
  return true  
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_ForceStopSDL()
  commonFunctions:SDLForceStop()
end

return Test