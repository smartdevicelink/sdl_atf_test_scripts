---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Policy Manager sends PTS to HMI by providing the file location,
-- timeout and the array of timeouts for retry sequence
--
-- Description:
-- SDL should request PTU in case getting device consent
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- 2. Performed steps
-- Application is registered. Getting device consent
-- PTU is requested.
--
-- Expected result:
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
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

--[[ Test ]]
function Test:TestStep_PolicyManager_sends_PTS_to_HMI()
  local is_test_fail = false
  local hmi_app_id = self.applications[config.application1.registerAppInterfaceParams.appName]

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)
      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)

          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})

          EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{})
          :Do(function(_,data)
            testCasesForPolicyTableSnapshot:verify_PTS(true,
              {config.application1.registerAppInterfaceParams.fullAppID},
              {utils.getDeviceMAC()},
              {hmi_app_id})

              local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
              local file_pts = SystemFilesPath.."/sdl_snapshot.json"
              if(data.params.file ~= file_pts) then
                commonFunctions:printError("Error: SystemFilePath is not as expected "..data.params.file..". Expected: "..file_pts)
                is_test_fail = true
              end
              if(is_test_fail == true) then
                self:FailTestCase("Test is FAILED. See prints.")
              end
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            end)
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
