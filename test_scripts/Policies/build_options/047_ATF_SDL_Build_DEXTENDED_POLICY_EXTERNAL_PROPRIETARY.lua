---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [GENIVI] [Policy] "EXTERNAL_PROPRIETARY flow:
--SDL must be build with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY"
--
-- Description:
-- To "switch on" the "Premium" (extended) Policies feature
-- -> SDL should be built with -DEXTENDED_POLICY: EXTERNAL_PROPRIETARY flag
-- 1. Performed steps
-- Build SDL with flag above
--
-- Expected result:
-- SDL is successfully built
-- The flag EXTENDED_POLICY is set to EXTERNAL_PROPRIETARY
-- PTU passes successfully

---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Device_Consented()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:TestStep_SUCCEESS_Flow_EXTERNAL_PROPRIETARY()
  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
