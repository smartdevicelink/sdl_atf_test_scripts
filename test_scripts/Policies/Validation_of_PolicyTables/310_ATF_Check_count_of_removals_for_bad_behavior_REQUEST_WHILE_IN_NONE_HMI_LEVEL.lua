---------------------------------------------------------------------------------------------

-- See APPLINK-23481, APPLINK-16147
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and "count_of_removals_for_bad_behavior" update
--
-- Description:
-- In case an application has been unregistered with any of:
-- -> TOO_MANY_PENDING_REQUESTS,
-- -> TOO_MANY_REQUESTS,
-- -> REQUEST_WHILE_IN_NONE_HMI_LEVEL resultCodes,
-- Policy Manager must increment "count_of_removals_for_bad_behavior" section value
-- of Local Policy Table for the corresponding application.

-- Pre-conditions:
-- a. SDL and HMI are started
-- b. app successfully registers and running in NONE

-- Steps:
-- 1. Application is sending more requests than AppHMILevelNoneTimeScaleMaxRequests in
-- AppHMILevelNoneRequestsTimeScale milliseconds:
-- appID->AnyRPC()
-- 2. Application is unregistered:
-- SDL->appID: OnAppUnregistered(REQUEST_WHILE_IN_NONE_HMI_LEVEL)

-- Expected:
-- 3. PoliciesManager increments value of <count_of_removals_for_bad_behavior>

-- Thic
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')
local mobile_session = require('mobile_session')

-- local variables
local count_of_requests = 10
-- local HMIAppID
--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- Precondition: application is activate
--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.ChangeIniFile( )
  Preconditions:BackupFile("smartDeviceLink.ini")
  commonFunctions:write_parameter_to_smart_device_link_ini("AppHMILevelNoneTimeScaleMaxRequests", count_of_requests)
  commonFunctions:write_parameter_to_smart_device_link_ini("AppHMILevelNoneRequestsTimeScale", 30000)
  commonFunctions:write_parameter_to_smart_device_link_ini("HMICapabilitiesCacheFile", "")
end

function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_initHMI()
  self:initHMI()
end

function Test:Precondition_initHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end

function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,_)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      EXPECT_RESPONSE(correlationId, { success = true })
      EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
end
--[[ end of Preconditions ]]

-- Precondition: application is NONE
function Test:Send_TOO_MANY_REQUESTS_WHILE_IN_NONE_HMI_LEVEL()
  local count_of_sending_requests = count_of_requests + 10
  for i = 1, count_of_sending_requests do
    self.mobileSession:SendRPC("AddCommand",
      {
        cmdID = i,
        menuParams =
        {
          position = 0,
          menuName ="Command"..tostring(i)
        }
      })
  end
  -- --mobile side: expect notification
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "REQUEST_WHILE_IN_NONE_HMI_LEVEL"})
end

function Test.Wait()
  os.execute("sleep 3")
end

function Test:Check_TOO_MANY_REQUESTS_in_DB()
  local db_path = config.pathToSDL.."storage/policy.sqlite"
  local sql_query = "SELECT count_of_removals_for_bad_behavior FROM app_level WHERE application_id = '" .. config.application1.registerAppInterfaceParams.fullAppID .. "'"
  local exp_result = {"1"}
  if commonFunctions:is_db_contains(db_path, sql_query, exp_result) == false then
    self:FailTestCase("DB doesn't include expected value")
  end
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end
function Test.RestoreIniFile()
  Preconditions:RestoreFile("smartDeviceLink.ini")
end

return Test
