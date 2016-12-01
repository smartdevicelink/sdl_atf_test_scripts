--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
commonSteps = require('user_modules/shared_testcases/commonSteps')
commonFunctions = require('user_modules/shared_testcases/commonFunctions')
testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')