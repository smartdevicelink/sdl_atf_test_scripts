---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] PoliciesManager must initiate PTU on a User request
-- [HMI API] UpdateSDL request/response
--
-- Description:
-- SDL should request PTU in case user requests PTU
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Application is registered.
-- No PTU is requested.
-- 2. Performed steps
-- User press button on HMI to request PTU.
-- HMI->SDL: SDL.UpdateSDL
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI: BasicCommunication.PolicyUpdate
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:Precondition_flow_SUCCEESS_EXTERNAL_PROPRIETARY()
  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self)
end

function Test.Precondition_Remove_PTS()
  os.execute("rm /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json")
  if( commonSteps:file_exists("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json") ~= false) then
    os.execute("rm /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json")
  end
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TC_User_PressButton_HMI_PTU()
  local is_test_fail = false
  local hmi_app1_id = self.applications[config.application1.registerAppInterfaceParams.appName]

  local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
  EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", { file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" })
  :Do(function(_,data)
      testCasesForPolicyTableSnapshot:verify_PTS(true,
        {config.application1.registerAppInterfaceParams.fullAppID},
        {utils.getDeviceMAC()},
        {hmi_app1_id})

      local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
      local seconds_between_retries = {}
      for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
        seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
        if(seconds_between_retries[i] ~= data.params.retry[i]) then
          commonFunctions:printError("Error: data.params.retry["..i.."]: "..data.params.retry[i] .."ms. Expected: "..seconds_between_retries[i].."ms")
          is_test_fail = true
        end
      end
      if(data.params.timeout ~= timeout_after_x_seconds) then
        commonFunctions:printError("Error: data.params.timeout = "..data.params.timeout.."ms. Expected: "..timeout_after_x_seconds.."ms.")
        is_test_fail = true
      end
      if(is_test_fail == true) then
        self:FailTestCase("Test is FAILED. See prints.")
      end
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
