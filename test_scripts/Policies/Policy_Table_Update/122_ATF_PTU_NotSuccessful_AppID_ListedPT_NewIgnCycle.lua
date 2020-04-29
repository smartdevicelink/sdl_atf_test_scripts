---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Policy Table Update in case of failed retry strategy during previous IGN_ON (SDL.PolicyUpdate)
-- [HMI API] PolicyUpdate request/response
-- Can you clarify the state of PTU(UPDATE_NEEDED) in previous ign_cycle according to ...
--
-- Description:
-- SDL should request PTU in case of failed retry strategy during previour IGN_ON
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Connect mobile phone over WiFi. Device is consented.
-- Register new application.
-- PTU is requested.
-- IGN OFF
-- 2. Performed steps
-- IGN ON.
-- Connect device. Application is registered.
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL-> HMI: SDL.PolicyUpdate()
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local hmi_app_id1, hmi_app_id2

--[[ General Precondition before ATF start ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
commonSteps:DeleteLogsFileAndPolicyTable()
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

function Test:Precondition_StartNewSession()
  self.mobileSession1 = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:Precondition_RegisterNewApplication()
  local is_test_fail = false
  hmi_app_id1 = self.applications[config.application1.registerAppInterfaceParams.appName]
  local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName } })
  :Do(function(_,_data2)
      hmi_app_id2 = _data2.params.application.appID

      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})

      EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{ file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" })
      :Do(function(_,_data3)
          testCasesForPolicyTableSnapshot:verify_PTS(true,
            {config.application1.registerAppInterfaceParams.fullAppID, config.application2.registerAppInterfaceParams.fullAppID},
            {utils.getDeviceMAC()},
            {hmi_app_id1, hmi_app_id2})

          local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
          local seconds_between_retries = {}
          for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
            seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
            if(seconds_between_retries[i] ~= _data3.params.retry[i]) then
              commonFunctions:printError("Error: data.params.retry["..i.."]: ".._data3.params.retry[i] .."ms. Expected: "..seconds_between_retries[i].."ms")
              is_test_fail = true
            end
          end
          if(_data3.params.timeout ~= timeout_after_x_seconds) then
            commonFunctions:printError("Error: data.params.timeout = ".._data3.params.timeout.."ms. Expected: "..timeout_after_x_seconds.."ms.")
            is_test_fail = true
          end
          if(is_test_fail == true) then
            self:FailTestCase("Test is FAILED. See prints.")
          end

          self.hmiConnection:SendResponse(_data3.id, _data3.method, "SUCCESS", {})
        end)
    end)
  self.mobileSession1:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
end

function Test:Precondition_Suspend()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
end

function Test:Precondition_IGNITION_OFF()
  StopSDL()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered"):Times(2)
end

function Test:Precondtion_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash, self)
end

function Test:Precondtion_initHMI()
  self:initHMI()
end

function Test:Precondtion_initHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondtion_ConnectMobile()
  self:connectMobile()
end

function Test:Precondtion_CreateSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PTU_NotSuccessful_AppID_ListedPT_NewIgnCycle()
  local is_test_fail
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.appName } })
  :Do(function(_,_)
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" })
      :Do(function(_,_data4)
          testCasesForPolicyTableSnapshot:verify_PTS(true,
            {config.application1.registerAppInterfaceParams.fullAppID, config.application2.registerAppInterfaceParams.fullAppID},
            {utils.getDeviceMAC()},
            {hmi_app_id1, hmi_app_id2})

          local timeout_after_x_seconds = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
          local seconds_between_retries = {}
          for i = 1, #testCasesForPolicyTableSnapshot.pts_seconds_between_retries do
            seconds_between_retries[i] = testCasesForPolicyTableSnapshot.pts_seconds_between_retries[i].value
            if(seconds_between_retries[i] ~= _data4.params.retry[i]) then
              commonFunctions:printError("Error: data.params.retry["..i.."]: ".._data4.params.retry[i] .."ms. Expected: "..seconds_between_retries[i].."ms")
              is_test_fail = true
            end
          end
          if(_data4.params.timeout ~= timeout_after_x_seconds) then
            commonFunctions:printError("Error: data.params.timeout = ".._data4.params.timeout.."ms. Expected: "..timeout_after_x_seconds.."ms.")
            is_test_fail = true
          end
          if(is_test_fail == true) then
            self:FailTestCase("Test is FAILED. See prints.")
          end
          self.hmiConnection:SendResponse(_data4.id, _data4.method, "SUCCESS", {})
        end)
    end)

  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
