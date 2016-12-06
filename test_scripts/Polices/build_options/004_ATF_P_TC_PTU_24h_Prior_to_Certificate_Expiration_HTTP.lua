--UNREADY
-- function needed to check expiration date of certificate against the current date
-- TestStep_Check_Exp_Date_of_Certificate_Against_Current
---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU]: In case current date is "24 hours prior to module`s certificate expiration date"
-- [INI file] [Security Manager] UpdateBeforeHours
--
-- Description:
-- PoliciesManager must start a PolicyTable Update sequence IN CASE the current 
--date is "24 hours prior to module's certificate expiration date"
-- 1. Used preconditions: 
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- SDL and HMI are started and running
-- Policies database exists with valid "certificate" in "module_config"
-- App is registered
-- 2. Performed steps:
-- -- Trigger for certificate expiration status check is IGN_ON 
-- SDL: Check expiration date of certificate against current date 
--
-- Expected result:
-- SDL: Start PT Exchange sequence
-- SDL->HMI: OnStatusUpdate("UPDATE_NEEDED")
-- PTU sequence is started 
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
--local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--TODO(mmihaylova): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]

commonFunctions:newTestCasesGroup("Preconditions")

commonSteps:DeleteLogsFileAndPolicyTable()

function Test:Precondition_RegisterApp() 
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
function Test.TestStep_Check_Exp_Date_of_Certificate_Against_Current()
  return false 
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test