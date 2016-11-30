-- UNREADY
-- function Test:TestStep_PTU_Merge is not developed
-- function testCasesForPolicyTable:flow_SUCCEESS_PROPRIETARY() is not developed 

---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] PoliciesManager changes status to “UP_TO_DATE”
-- [HMI API] OnStatusUpdate
-- [HMI API] OnReceivedPolicyUpdate notification
--
-- Description:
--PoliciesManager must change the status to “UP_TO_DATE” and notify HMI with 
--OnStatusUpdate("UP_TO_DATE") right after successful validation of received PTU .
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: ON" flag
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:PROPRIETARY)
-- SDL->app: OnSystemRequest ('url', requestType:PROPRIETARY, fileType="JSON")
-- app->SDL: SystemRequest(requestType=PROPRIETARY)
-- SDL->HMI: SystemRequest(requestType=PROPRIETARY, fileName)
-- HMI->SDL: SystemRequest(SUCCESS)
-- 2. Performed steps
-- HMI->SDL: OnReceivedPolicyUpdate(policy_file) according to data dictionary
--
-- Expected result:
-- SDL->HMI: OnStatusUpdate(UP_TO_DATE)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForBuildingSDLPolicyFlag = require('user_modules/shared_testcases/testCasesForBuildingSDLPolicyFlag')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
testCasesForBuildingSDLPolicyFlag:Update_PolicyFlag("EXTENDED_POLICY", "PROPRIETARY")
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("EXTENDED_POLICY","PROPRIETARY")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PoliciesManager_changes_UP_TO_DATE()
  testCasesForPolicyTable:flow_PTU_SUCCEESS_PROPRIETARY(self)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {}):Times(0)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{}):Times(0)
  commonTestCases:DelayedExp(60*1000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test:Postcondition_Force_Stop_SDL()
  commonFunctions:SDLForceStop(self)
end

return Test