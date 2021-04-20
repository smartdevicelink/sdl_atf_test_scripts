---------------------------------------------------------------------------------------------
-- Requirement summary:
--    [Policies] "pre_DataConsent", <app id>, "default" policies and "appHMIType" validation
--
-- Description:
--     Validation of "appHMIType" sub-section in "<app ID" if "<app ID>" policies assigned to the application
--     1. Used preconditions:
--      Delete logs file and policy table
--      Set appHMIType for "<app ID>" policies
--      Connect device
--      Add session
--
--     2. Performed steps
--      Activate registered app-> PTU triggered
--
-- Expected result:
--     PoliciesManager must validate "appHMIType" sub-section in "<app ID>" and treat it as valid -> PTU is valid
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--[ToDo: should be removed when fixed: "ATF does not stop HB timers by closing session and connection"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Validate_default_hmi_upon_PTU()
  local ptu_file_path = "files/"
  local ptu_file = "PTU_AppIDAppHMIType.json"
  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self, nil, nil, nil, ptu_file_path, nil, ptu_file)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
