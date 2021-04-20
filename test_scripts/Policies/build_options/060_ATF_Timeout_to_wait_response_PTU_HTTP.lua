---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Timeout to wait a response on PTU
--
-- Description:
-- To define the timeout to wait a response on PTU, Policies manager must refer
--PTS "module_config" section, key <timeout_after_x_seconds>.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- 2. Performed steps
-- Application is registered.
-- PTU is requested.
--
-- Expected result:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:BC.PolicyUpdate(file, timeout, retry[]) where
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local json = require("modules/json")

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require("user_modules/AppTypes")

--[[ Local Variables ]]
local timeout_preloaded = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("module_config.timeout_after_x_seconds")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:RAI()
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function(_, d1)
      self.applications[config.application1.registerAppInterfaceParams.fullAppID] = d1.params.application.appID
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" } )
      :Times(2)
    end)
  self.mobileSession:ExpectNotification("OnSystemRequest")
  :Times(2)
  :ValidIf(function(_, d2)
    if d2.payload.requestType =="LOCK_SCREEN_ICON_URL" then return true end
    if d2.payload.requestType == "HTTP" then
        if d2.binaryData then
          local ptu_table = json.decode(d2.binaryData)
          local timeout_pts = ptu_table.policy_table.module_config.timeout_after_x_seconds
          print("Timeout expected: " .. timeout_preloaded .. "s")
          print("Timeout actual: " .. timeout_preloaded .. "s")
          if ( timeout_pts == timeout_preloaded ) then return true end
          return false, "timeout in PTS should be "..tostring(timeout_preloaded).."s, real: "..tostring(timeout_pts).."s"
        end
      end
    end)
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
