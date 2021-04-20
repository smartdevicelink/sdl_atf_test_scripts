---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] WiFi/USB: At least one application is registered
-- [HMI API] OnStatusUpdate
-- [HMI API] PolicyUpdate request/response
--
-- Description:
-- PoliciesManager may initiate the PTUpdate sequence in case the first application has registered.
-- Clarification for first application registered: For WiFI and USB PTU sequence must be initiated
-- in case this sequence was triggered by existing rules (24 hour due to certificate`s expiration,
-- appID of app is NOT listed at PolicyTable, etc.)
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Connect mobile phone over WiFi. Device is consented.
-- Register new application.
-- SDL->HMI: OnAppRegistered()
--
-- Expected result:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL-> HMI: SDL.PolicyUpdate()
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

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_Getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:Precondition_flow_SUCCEESS_EXTERNAL_PROPRIETARY()
  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self)
end

function Test.Precondition_Delete_PTS()
  testCasesForPolicyTable.Delete_Policy_table_snapshot()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_StartNewSession()
  self.mobileSession1 = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:TestStep_PTU_AppID_NotListed_PT_WiFi()
  local is_test_fail = false
  local hmi_app_id1 = self.applications[config.application1.registerAppInterfaceParams.appName]
  local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName } })
  :Do(function(_,data)
      local hmi_app_id2 = data.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})

      EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" })
      :Do(function(_,_data1)
        testCasesForPolicyTableSnapshot:verify_PTS(true,
        {config.application1.registerAppInterfaceParams.fullAppID, config.application1.registerAppInterfaceParams.fullAppID},
        {utils.getDeviceMAC()},
        {hmi_app_id1, hmi_app_id2})

      local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
      local seconds_between_retries = {}
      for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
        seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
        if(seconds_between_retries[i] ~= _data1.params.retry[i]) then
          commonFunctions:printError("Error: data.params.retry["..i.."]: ".._data1.params.retry[i] .."ms. Expected: "..seconds_between_retries[i].."ms")
          is_test_fail = true
        end
      end
      if(_data1.params.timeout ~= timeout_after_x_seconds) then
        commonFunctions:printError("Error: data.params.timeout = ".._data1.params.timeout.."ms. Expected: "..timeout_after_x_seconds.."ms.")
        is_test_fail = true
      end
    if(is_test_fail == true) then
      self:FailTestCase("Test is FAILED. See prints.")
    end
          self.hmiConnection:SendResponse(_data1.id, _data1.method, "SUCCESS", {})
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
