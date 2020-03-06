---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Timeout to wait a response on PTU
--
-- Description:
-- SDL should request PTU in app is registered and getting device consent
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
-- 2. Performed steps
-- Application is registered.
-- PTU is requested.
--
-- Expected result:
-- To define the timeout to wait a response on PTU, Policies manager must refer PTS
-- "module_config" section, key <timeout_after_x_seconds>.
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPTS = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local mobile_session = require('mobile_session')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local default_app_params = config.application1.registerAppInterfaceParams

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Start_SDL()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
      self:initHMI():Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMI_onReady():Do(function ()
              commonFunctions:userPrint(35, "HMI is ready")
              self:connectMobile():Do(function ()
                  commonFunctions:userPrint(35, "Mobile Connected")
                end)
            end)
        end)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTS_Timeout_wait_response_PTU()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = self.mobileSession:StartRPC()
  on_rpc_service_started:Do(function()
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", default_app_params)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered"):Do(function(_,data)
          self.HMIAppID = data.params.application.appID
        end)
      self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus",
        {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"})
      :Times(2)
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end)
      :ValidIf(function(_,data)
          local timeout_after_x_seconds_preloaded =
          testCasesForPTS:get_data_from_Preloaded_PT("module_config.timeout_after_x_seconds")
          local timeout_after_x_seconds = testCasesForPTS:get_data_from_PTS("module_config.timeout_after_x_seconds")

          if(timeout_after_x_seconds_preloaded ~= timeout_after_x_seconds) then
            commonFunctions:printError("Error: PTS: timeout_after_x_seconds = "..data.params.timeout..
              "ms is not as expected. Expected: "..timeout_after_x_seconds_preloaded.."ms.")
            return false
          else
            if(data.params.timeout ~= timeout_after_x_seconds) then
              commonFunctions:printError("Error: data.params.timeout = "..data.params.timeout..
                "ms. Expected: "..timeout_after_x_seconds.."ms.")
              return false
            else
              return true
            end
          end
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
