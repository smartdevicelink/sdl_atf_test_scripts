---------------------------------------------------------------------------------------------
-- Requirements summary:
-- In case HMI sends SDL.GetPolicyConfigurationData SDL must return endpoints json as value
--
-- Description:
-- In case HMI sends GetPolicyConfigurationData (policyType = "module_config", property = "endpoints")
-- SDL must return policy_table.module_config.endpoints of PolicyDataBase as json
--
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered. AppID is listed in PTS
-- No PTU is requested.
-- 2. Performed steps
-- Unregister application.
-- User press button on HMI to request PTU.
-- HMI->SDL: SDL.GetPolicyConfigurationData(policyType = "module_config", property = "endpoints")
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL.GetPolicyConfigurationData({value = <endpoints json>})
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ General Precondition before ATF start ]]
local testPtFilePath = "files/jsons/Policies/Policy_Table_Update/endpoints_appId.json"
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(testPtFilePath)
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test.Precondition_Wait()
  commonTestCases:DelayedExp(1000)
end

function Test:Precondition_UnregisterApp()
  self.mobileSession:SendRPC("UnregisterAppInterface", {})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  EXPECT_RESPONSE("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU_GetURLs_NoAppRegistered()
  local expUrls = commonFunctions:getUrlsTableFromPtFile(testPtFilePath)
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
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
