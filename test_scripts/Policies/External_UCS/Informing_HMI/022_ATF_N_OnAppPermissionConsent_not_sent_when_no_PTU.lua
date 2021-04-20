---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] [External UCS] SDL informs HMI about <externalConsentStatus> via GetListOfPermissions response
-- [HMI API] GetListOfPermissions request/response
-- [HMI API] ExternalConsentStatus struct & EntityStatus enum
-- "Clarification: When onAppPermission Changed should be sent"
--
--
-- Description:
-- For Genivi applicable ONLY for 'EXTERNAL_PROPRIETARY' Polcies
-- Check that no OnAppPermissionConsent notification (precondition for GetListofPermissions) is not sent if PTU did not take place
--
-- 1. Used preconditions
-- SDL is built with External_Proprietary flag
-- SDL and HMI are running
-- Device is not consented and PTU does not take place
--
-- 2. Performed steps
-- Activate app in order to trigger PTU
--
-- Expected result:
-- PTU is triggered
-- HMI notification SDL.OnAppPermissionChanged is not sent
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_No_PTU_No_OnAppPermissionConsent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
  EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged"):Times(0)
  commonTestCases:DelayedExp(10000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
