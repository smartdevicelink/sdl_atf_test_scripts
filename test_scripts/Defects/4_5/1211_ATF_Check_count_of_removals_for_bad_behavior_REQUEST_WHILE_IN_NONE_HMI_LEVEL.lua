----------------------------------------------------------------------------------------------------
-- Script verifies issue https://github.com/SmartDeviceLink/sdl_core/issues/1211
-- Flow: EXTERNAL_PROPRIETARY
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require("user_modules/script_runner")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local mobile_session = require("mobile_session")
local common = require("test_scripts/Defects/4_5/commonDefects")
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

--[[ General configuration parameters ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }
-- switch ATF to mode when it will continue test script execution even if SDL crashes
config.ExitOnCrash = false

-- [[Local variables]]
-- define number of requests that have to be sent
local count_of_requests = 10

--[[ @updateINIFile: update parameters in SDL .ini file
--! @parameters: none
--! @return: none
--]]
local function updateINIFile()
  -- backup .ini file
  common.backupINIFile()
  -- change the value of 'AppHMILevelNoneTimeScaleMaxRequests' parameter
  commonFunctions:write_parameter_to_smart_device_link_ini("AppHMILevelNoneTimeScaleMaxRequests", count_of_requests)
  -- change the value of 'AppHMILevelNoneRequestsTimeScale' parameter
  commonFunctions:write_parameter_to_smart_device_link_ini("AppHMILevelNoneRequestsTimeScale", 30000)
end

--[[ @registerApp: create mobile session, start RPC service and register mobile application
--! @parameters:
--! self - test object which will be provided automatically by runner module
--! @return: none
--]]
local function registerApp(self)
  -- create mobile session
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  -- start RPC service
  self.mobileSession:StartService(7)
  :Do(function ()
      -- send 'RegisterAppInterface' RPC with default parameters for mobile application
      -- and return correlation identifier
      local cid = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      -- register expectation of 'BC.OnAppRegistered' notification on HMI connection
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      -- register expectation of response for 'RegisterAppInterface' request with appropriate correlation id
      -- on Mobile connection
      EXPECT_RESPONSE(cid, { success = true })
      -- register expectation of 'OnPermissionsChange' notification on Mobile connection
      EXPECT_NOTIFICATION("OnPermissionsChange")
      -- register expectation of 'OnHMIStatus' notification on Mobile connection
      -- it's expected that value of 'hmiLevel' parameter will be 'NONE'
      self.mobileSession:ExpectNotification("OnHMIStatus", {
        hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
      })
    end)
end

--[[ @Send_TOO_MANY_REQUESTS_WHILE_IN_NONE_HMI_LEVEL: send predefined number of requests
--! 'AddCommand' RPC will be sent (count_of_requests + 10) number of times
--! @parameters:
--! self - test object which will be provided automatically by runner module
--! @return: none
--]]
local function Send_TOO_MANY_REQUESTS_WHILE_IN_NONE_HMI_LEVEL(self)
  -- define number of requests that will be sent
  local count_of_sending_requests = count_of_requests + 10
  -- define loop where RPC will be sent several times one by one
  for i = 1, count_of_sending_requests do
    -- send 'AddCommand' RPC with some parameters
    self.mobileSession:SendRPC("AddCommand", {
      cmdID = i,
      menuParams =
      {
        position = 0,
        menuName ="Command" .. tostring(i)
      }
    })
  end
  -- register expectation of 'OnAppInterfaceUnregistered' notification on Mobile connection
  -- it's expected that value of 'reason' parameter will be 'REQUEST_WHILE_IN_NONE_HMI_LEVEL'
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "REQUEST_WHILE_IN_NONE_HMI_LEVEL"})
end

--[[ @Wait: wait 3 sec.
--! @parameters: none
--! @return: none
--]]
local function Wait()
  -- invoke 'DelayedExp' function of 'commonTestCases' module with parameter of '3000' msec.
  commonTestCases:DelayedExp(3000)
end

--[[ @Check_TOO_MANY_REQUESTS_in_DB: check value of 'count_of_removals_for_bad_behavior' in Local Policy Database
--! @parameters:
--! self - test object which will be provided automatically by runner module
--! @return: none
--]]
local function Check_TOO_MANY_REQUESTS_in_DB(self)
  -- define path to SQLite database file that is Local Policy Database
  local db_path = config.pathToSDL.."storage/policy.sqlite"
  -- define query which is going to be executed
  local sql_query = "SELECT count_of_removals_for_bad_behavior FROM app_level WHERE application_id = '"
    .. config.application1.registerAppInterfaceParams.fullAppID .. "'"
  -- define expected value for the query
  -- it's expected that the value of 'count_of_removals_for_bad_behavior' parameter will be increased from '0' to '1'
  local exp_result = {"1"}
  -- compare actual value in database against the expected one
  if commonFunctions:is_db_contains(db_path, sql_query, exp_result) == false then
    -- fail test step if the values are different
    self:FailTestCase("DB doesn't include expected value")
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update INI file", updateINIFile)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("SDL Configuration", common.printSDLConfig)

runner.Title("Test")
runner.Step("Register App", registerApp)
runner.Step("Send_TOO_MANY_REQUESTS_WHILE_IN_NONE_HMI_LEVEL", Send_TOO_MANY_REQUESTS_WHILE_IN_NONE_HMI_LEVEL)
runner.Step("Wait 3sec", Wait)
runner.Step("Check_TOO_MANY_REQUESTS_in_DB", Check_TOO_MANY_REQUESTS_in_DB)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore INI file", common.restoreINIFile)
