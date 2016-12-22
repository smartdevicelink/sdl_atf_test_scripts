---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PreloadedPT] At least one optional param has invalid type
--
-- Description:
-- Behavior of SDL during start SDL with Preloaded PT file with one optional parameter that has invalid type
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Create PreloadedPolicyTable file with one optional parameter that has invalid type
-- Start SDL
--
-- Expected result:
-- PolicyManager shut SDL down
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2

--[[ General configuration parameters ]]
Test = require('connecttest')
require("user_modules/AppTypes")

function Test:Precondition_StopSDL()
  StopSDL(self)
end

function Test.Precondition()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
  commonPreconditions:BackupFile("sdl_preloaded_pt.json")
  testCasesForPolicySDLErrorsStops.updatePreloadedPT("data.policy_table.module_config", {certificate = 557089})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_checkSdlShutdown()
  -- function will return true if SDL stops
  local result = testCasesForPolicySDLErrorsStops:CheckSDLShutdown(self)
  if (result == false) then
    self:FailTestCase("Error: SDL should stop.")
  end
end

function Test:TestStep_CheckSDLLogError()
  -- function will return true if error message is listed in log
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized.")
  if (result == false) then
    self:FailTestCase("Error: message 'Policy table is not initialized.' is not observed in smartDeviceLink.log.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop()
  StopSDL()
end

return Test