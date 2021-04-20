---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Request PTU - an app registered is not listed in PT (device consented)
--
-- Description:
-- SDL should request PTU in case new application is registered and is not listed in PT
-- and device is consented.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Connect mobile phone over WiFi.
-- Register new application.
-- Successful PTU. Device is consented.
-- 2. Performed steps
-- Register new application
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI: BasicCommunication.PolicyUpdate
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

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
testCasesForPolicyTable.Delete_Policy_table_snapshot()


--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:Precondition_flow_SUCCEESS_EXTERNAL_PROPRIETARY()
  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_StartNewSession()
  self.mobileSession1 = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:TestStep_PTU_AppID_SecondApp_NotListed_PT()
  local is_test_fail = false
  local hmi_app1_id = self.applications[config.application1.registerAppInterfaceParams.appName]

  local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName } })
  :Do(function(_,data)
      local hmi_app2_id = data.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})

      EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{ file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" })
      :Do(function(_,data1)
         testCasesForPolicyTableSnapshot:verify_PTS(true, {
            config.application1.registerAppInterfaceParams.fullAppID,
            config.application2.registerAppInterfaceParams.fullAppID,
          },
          {utils.getDeviceMAC()},
          {hmi_app1_id, hmi_app2_id})

          local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
          local seconds_between_retries = {}
          for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
            seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
            if(seconds_between_retries[i] ~= data1.params.retry[i]) then
              commonFunctions:printError("Error: data.params.retry["..i.."]: "..data1.params.retry[i] .."ms. Expected: "..seconds_between_retries[i].."ms")
              is_test_fail = true
            end
          end
          if(data1.params.timeout ~= timeout_after_x_seconds) then
            commonFunctions:printError("Error: data.params.timeout = "..data1.params.timeout.."ms. Expected: "..timeout_after_x_seconds.."ms.")
            is_test_fail = true
          end
          if(is_test_fail == true) then
            self:FailTestCase("Test is FAILED. See prints.")
          end
          self.hmiConnection:SendResponse(data1.id, data1.method, "SUCCESS", {})
        end)
    end)
  self.mobileSession1:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
