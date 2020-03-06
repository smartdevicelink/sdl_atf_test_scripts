---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] Treating the device as consented
--
-- Description:
-- Condition for device to be consented
-- 1. Used preconditions:
-- Close current connection
-- Overwrite preloaded policy table to have group both listed in 'device' and 'preconsented_groups' sub-sections of 'app_policies' section
-- Connect device for the first time
-- Register app running on this device
-- 2. Performed steps
-- Activate app: HMI->SDL: SDL.ActivateApp => Policies Manager treats the device as consented => no consent popup appears => SDL->HMI: SDL.ActivateApp(isSDLAllowed: true, params)
--
-- Expected result:
-- Policies Manager must treat the device as consented If "device" sub-section of "app_policies" has its group listed in "preconsented_groups".
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/DeviceGroupInPreconsented_preloadedPT.json")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_TreatDeviceAsConsented()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp",
    { appID = self.applications[config.application1.registerAppInterfaceParams.appName] })
  EXPECT_HMIRESPONSE(RequestId, { isSDLAllowed = true } )
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end
