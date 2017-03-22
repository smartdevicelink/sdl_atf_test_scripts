---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Timeout to wait a response on PTU
--
-- Description:
-- SDL should request PTU in app is registered and getting device consent
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- 2. Performed steps
-- Application is registered.
-- PTU is requested.
--
-- Expected result:
-- To define the timeout to wait a response on PTU, Policies manager must refer PTS
-- "module_config" section, key <timeout_after_x_seconds>.
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PTS_Timeout_wait_response_PTU()
  local is_test_fail = false
  local hmi_app_id = self.applications[config.application1.registerAppInterfaceParams.appName]
  local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)
      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = ServerAddress, isSDLAllowed = true}})
        end)
    end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{})
  :Do(function(_,data)
    testCasesForPolicyTableSnapshot:verify_PTS(true,
      {config.application1.registerAppInterfaceParams.appID},
      {config.deviceMAC},
      {hmi_app_id})

      local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("module_config.timeout_after_x_seconds")

      if(data.params.timeout ~= timeout_after_x_seconds) then
        commonFunctions:printError("Error: Timeout to wait response = "..data.params.timeout.."ms. Expected: "..timeout_after_x_seconds.."ms.")
        is_test_fail = true
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