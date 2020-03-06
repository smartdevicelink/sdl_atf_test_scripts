---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] SDL.ActivateApp from HMI and 'isPermissionsConsentNeeded' parameter in the response
-- [HMI API] SDL.ActivateApp (Genivi)
--
-- Description:
-- SDL receives request for app activation from HMI and LocalPT contains permission that don't require User`s consent
-- 1. Used preconditions:
-- Delete SDL log file and policy table
--
-- 2. Performed steps
-- Activate with default permissions, Base-4
--
-- Expected result:
-- On receiving SDL.ActivateApp PoliciesManager must respond with "isPermissionsConsentNeeded:false"
-- to HMI, consent for custom permissions is not appeared
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:IsPermissionsConsentNeeded_false_on_app_activation()
  local is_test_fail = false
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId,{ result = { code = 0, method = "SDL.ActivateApp", isPermissionsConsentNeeded = false, isSDLAllowed = false}})
  :Do(function(_,data)
      if (data.result.isPermissionsConsentNeeded ~= false) then
        commonFunctions:printError("Wrong SDL behavior: isPermissionsConsentNeeded should be false for app with Base-4 permissions.")
        is_test_fail = true
      end
      if (data.result.priority ~= nil) then
        if (data.result.priority ~= "NONE") then
          is_test_fail = true
          commonFunctions:printError("Wrong SDL behavior: priority should be NONE for app with Base-4 permissions.")
        end
      end

      if(is_test_fail == true) then
        self:FailTestCase("Test is FAILED. See prints.")
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
