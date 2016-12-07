---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] PreloadPT the only one invalid value in "RequestType" array
--
-- Description:
-- Behavior of SDL during start SDL in case when PreloadedPT has one value in "RequestType" array and it is invalid
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Add one invalid value in "RequestType" array in PreloadedPT json file
-- Start SDL with created PreloadedPT json file
--
-- Expected result:
-- SDL must shutdown
---------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicySDLErrorsStops = require ('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ Local Variables ]]
local PRELOADED_PT_FILE_NAME = "sdl_preloaded_pt.json"

--[[ General Settings for configuration ]]
Test = require('connecttest')
require("user_modules/AppTypes")

--[[ Preconditions ]]
function Test:Precondition_stop_sdl()
  StopSDL(self)
end

function Test.TestStep_updatePreloadedPT()
  local testParameters = {RequestType = {"IVSU"} }
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
  commonPreconditions:BackupFile(PRELOADED_PT_FILE_NAME)
  testCasesForPolicySDLErrorsStops.updatePreloadedPT("data.policy_table.app_policies.default", testParameters)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_checkSdl_Running()
  --In case SDL stops function will return true
  local result = testCasesForPolicySDLErrorsStops:CheckSDLShutdown(self)
  if (result ~= true) then
    self:FailTestCase("Error: SDL should be stopped.")
  end
end

function Test:TestStep_CheckSDLLogError()
  --function will return true in case error is observed in smartDeviceLink.log
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized.")
  if (result ~= true) then
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