---------------------------------------------------------------------------------------------
-- Requirements summary:
--[PolicyTableUpdate] New application has registered and doesn't yet exist in Local PT
-- during PTU in progress
--
-- Description:
--PoliciesManager must add the appID of the newly registered app to the Local PT
--in case such appID does not yet exist in Local PT and PoliciesManager has sent the PT Snapshot
--and has not received the PT Update yet.

-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- App 1 is registered.
-- App 2 NOT yet registered on SDL and doesn't yet exist in LocalPT
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- 2. Performed steps
-- app_2->SDL:RegisterAppInterface()
--
-- Expected result:
-- SDL->App 2: SUCCESS:RegsterAppInterface()
-- SDL adds application with App 2 data into LocalPT according to general rules
-- of adding app data into LocalPT
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local mobile_session = require('mobile_session')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup ("Test")
function Test:TestStep_OpenNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:TestStep_RAI_NewSession()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application2.registerAppInterfaceParams.appName }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
end

function Test.Wait()
  commonTestCases:DelayedExp(5000)
end

function Test:TestStep_CheckThatAppID_SecondApp_Present_In_DataBase()
  local db_file = config.pathToSDL .. "/storage/policy.sqlite"
  local sql = "SELECT id FROM application WHERE id = '" .. config.application2.registerAppInterfaceParams.fullAppID .. "'"
  local AppIdValue_2 = commonFunctions:get_data_policy_sql(db_file, sql)
  if AppIdValue_2 == nil then
    self:FailTestCase("Value in DB is unexpected value " .. tostring(AppIdValue_2))
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Stop()
  StopSDL()
end

return Test
