---------------------------------------------------------------------------------------------
-- Requirement summary:
-- Policies]: Local PolicyTable Snapshot: Validation rules for required parameters
--
-- Check SDL behavior in case optional parameter absent/present in created PT snapshot
-- 1. Used preconditions:
-- Do not start default SDL
-- 2. Performed steps:
-- Set correct PathToSnapshot path in INI file
-- Start SDL
-- Initiate PT snapshot creation
--
-- Expected result:
-- SDL must store the PT snapshot without required parameters log the corresponding error internally and keep running
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start]]
config.defaultProtocolVersion = 2
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require("user_modules/AppTypes")
local SDL = require('modules/SDL')

function Test.checkSdl()
  local status = SDL:CheckStatusSDL()
  if status ~= SDL.RUNNING then
    commonFunctions:userPrint(31, "Test failed: SDL stopped without optional parameters in PT snapshot")
    return false
  end
  return true
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_CheckPTS()
  local result = testCasesForPolicyTableSnapshot:verify_PTS(true,
            {config.application1.registerAppInterfaceParams.fullAppID},
            {utils.getDeviceMAC()},
            {self.applications[config.application1.registerAppInterfaceParams.appName]},
            "print")
   if(result == false) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
