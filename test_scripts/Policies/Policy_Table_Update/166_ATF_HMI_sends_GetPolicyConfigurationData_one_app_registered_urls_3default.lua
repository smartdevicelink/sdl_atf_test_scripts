---------------------------------------------------------------------------------------------
-- Requirements summary:
-- In case HMI sends SDL.GetPolicyConfigurationData SDL must return endpoints json as value
-- [HMI API] SDL.GetPolicyConfigurationData request/response
--
-- Description:
-- SDL should request PTU in case getting device consent
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- In sdl_preloaded_pt.json for service 0x07 are listed 3 defaults urls
-- Application is registered. Device is consented.
-- PTU is requested.
-- 2. Performed steps
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
local testPtFilePath = "files/jsons/Policies/Policy_Table_Update/few_endpoints_appId_default.json"
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(testPtFilePath)

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
  local expUrls = commonFunctions:getUrlsTableFromPtFile(testPtFilePath)
  testCasesForPolicyTableSnapshot:extract_pts(
    {config.application1.registerAppInterfaceParams.fullAppID},
    {self.applications[config.application1.registerAppInterfaceParams.appName]})

  local RequestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetPolicyConfigurationData"} } )
  :ValidIf(function(_,data)
    return commonFunctions:validateUrls(expUrls, data)
  end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
