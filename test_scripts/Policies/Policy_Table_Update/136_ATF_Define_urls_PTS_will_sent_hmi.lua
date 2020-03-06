---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Define the URL(s) the PTS will be sent to
-- [HMI API] GetURLs request/response
--
-- Description:
-- SDL should request PTU in case user requests PTU
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- 2. Performed steps
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
--
-- Expected result:
-- SDL.GetURLs({urls[] = default}, (<urls>, appID))
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/Policy_Table_Update/few_endpoints_appId.json")

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
function Test:TestStep_PTU_GetURLs_AppRegistered()
  local is_test_fail = false
  local policy_endpoints = {}

  local sevices_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select service from endpoint")

  for _, value in pairs(sevices_table) do
    policy_endpoints[#policy_endpoints + 1] = { found = false, service = value }
    --TODO(istoimenova): Should be updated when policy defect is fixed
      if ( value == "0x04" or value == "0x07" or value == "0x01") then
        policy_endpoints[#policy_endpoints].found = true
      end
  end

  for i = 1, #policy_endpoints do
    if(policy_endpoints[i].found == false) then
      commonFunctions:printError("endpoints for service "..policy_endpoints[i].service .. " should not be observed." )
      is_test_fail = true
    end
  end

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end

end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
