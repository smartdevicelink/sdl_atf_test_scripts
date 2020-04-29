---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Policy Manager responds on GetPolicyConfigurationData from HMI
-- In case HMI sends SDL.GetPolicyConfigurationData SDL must return endpoints json as value
-- [HMI API] SDL.GetPolicyConfigurationData request/response
--
-- Description:
-- SDL should request PTU in case getting device consent
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Application is registered.
-- User request device consent
-- HMI->SDL: SDL.GetPolicyConfigurationData(policyType = "module_config", property = "endpoints")
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL.GetPolicyConfigurationData({value = <endpoints json>})
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

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
function Test:TestStep_PTU_GetURLs()
  local expUrls = commonFunctions:getUrlsTableFromPtFile()
  local RequestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetPolicyConfigurationData" } })
  :ValidIf(function(_,data)
    return commonFunctions:validateUrls(expUrls, data)
  end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
