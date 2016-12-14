---------------------------------------------------------------------------------------------
-- UnReady
-- Iliyana, please have a look on this script it have the same behavior like in script of this request:
-- https://github.com/smartdevicelink/sdl_atf_test_scripts/pull/157?
--
-- Requirements summary:
-- [PolicyTableUpdate] Timeout to wait a response on PTU
--
-- Description:
-- SDL should request PTU in case user requests PTU
-- 1. Used preconditions
-- SDL is built with "EXTENDED_POLICY: PROPRIETARY" flag
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
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_RAI.lua")

--TODO(anikolaev): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_RAI')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test.Precondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_RAI.lua" )
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_ConnectMobile()
  self:connectMobile()
end

function Test:TestStep_StartNewSession()
  self.mobileSession = mobile_session.MobileSession( self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:TestStep_PTS_Timeout_wait_response_PTU()
  local hmi_app_id = self.applications[config.application1.registerAppInterfaceParams.appName]
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.appName } })
  :Do(function(_,_)
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})

      testCasesForPolicyTableSnapshot:verify_PTS(true,
        {config.application1.registerAppInterfaceParams.appID},
        {config.deviceMAC},
        {hmi_app_id})

      local timeout_pts = testCasesForPolicyTableSnapshot:get_data_from_PTS("module_config.timeout_after_x_seconds")
      local timeout_preloaded
      for i = 1, #testCasesForPolicyTableSnapshot.preloaded_elements do
        if(testCasesForPolicyTableSnapshot.preloaded_elements[i].name == "module_config.timeout_after_x_seconds") then
          timeout_preloaded = testCasesForPolicyTableSnapshot.preloaded_elements[i].value
        end
      end
      if ( timeout_pts ~= timeout_preloaded ) then
        self:FailTestCase("timeout in PTS should be "..timeout_preloaded.."ms, real: "..timeout_pts.."ms")
      end
    end)
  self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test:Postcondition_Force_Stop_SDL()
  commonFunctions:SDLForceStop(self)
end

