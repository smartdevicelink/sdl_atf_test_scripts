---------------------------------------------------------------------------------------------
-- Requirements summary:
-- PoliciesManager must use the values from "seconds_between_retries" section of
-- Local PT as the values to provide in UpdateSDL request to notify SyncP manager to start PTU sequence.
--
-- Description:
-- SDL should request PTU in case getting device consent
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- 2. Performed steps
-- Application is registered. Getting device consent.
-- PTU is requested.
--
-- Expected result:
-- Number and values of the "retry" elements are provided as appropriate elements in
-- "seconds_between_retries" section of Local PT.
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_RAI.lua")

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PTS_Timeout_wait_response_PTU()
  local hmi_app_id = self.applications[config.application1.registerAppInterfaceParams.appName]

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)
      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})
      end)

      EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{})
      :Do(function(_,_)
        testCasesForPolicyTableSnapshot:verify_PTS(true,
            {config.application1.registerAppInterfaceParams.fullAppID},
            {utils.getDeviceMAC()},
            {hmi_app_id})
        local seconds_between_retries_pts = testCasesForPolicyTableSnapshot.seconds_between_retries
        local seconds_between_retries_preloaded = {}

          for i = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
            local str_1 = testCasesForPolicyTableSnapshot.preloaded_elements[i].name
            local str_2 = "module_config.seconds_between_retries"
            if(string.sub(str_1,1,string.len(str_2)) == str_2) then
              seconds_between_retries_preloaded[#seconds_between_retries_preloaded + 1] = testCasesForPolicyTableSnapshot.preloaded_elements[i]
            end
          end

          if(#seconds_between_retries_preloaded ~= #seconds_between_retries_pts) then
            self:FailTestCase("Numbers of seconds_between_retries should be "..#seconds_between_retries_preloaded ..", real: "..#seconds_between_retries_pts)
          else
            for i = 1, #seconds_between_retries_preloaded do
              if(seconds_between_retries_preloaded[i].value ~= seconds_between_retries_pts[i].value) then
                self:FailTestCase("seconds_between_retries["..i.."] should be "..seconds_between_retries_preloaded[i].value ..", real: "..seconds_between_retries_pts[i].value)
              end
            end
          end
      end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
