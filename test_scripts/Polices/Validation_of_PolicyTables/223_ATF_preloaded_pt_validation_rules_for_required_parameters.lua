---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: PreloadedPolicyTable: Validation rules for required parameters
--
-- Description:
-- Behavior of SDL during start SDL in case when PreloadedPT has no required parameters
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Create PreloadedPolicyTable file without one required parameter
-- Start SDL
--
-- Expected result:
-- SDL is shutdown
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2

--[[ Local Variables ]]
local PRELOADED_PT_FILE_NAME = "sdl_preloaded_pt.json"
local TEST_DATA = {
  ["1234"] = {
    [123] = "http://cloud.ford.com/global",
    keep_context = false,
    steal_focus = false,
    -- priority = "NONE", -- removed required parameter
    default_hmi = "NONE",
    groups = {"BaseBeforeDataConsent"}
  },
  super = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"BaseBeforeDataConsent"}
  }
}

--[[ General configuration parameters ]]
Test = require('connecttest')
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test:Precondition_StopSdl()
  StopSDL(self)
end

function Test.Precondition_UpdatePreloadedPT()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
  commonPreconditions:BackupFile(PRELOADED_PT_FILE_NAME)
  testCasesForPolicySDLErrorsStops.updatePreloadedPT("data.policy_table.app_policies", TEST_DATA)
end

--[[ Test ]]
function Test:Test_StartSdl()
  --TODO(istoimenova): Should be checked when ATF problem is fixed with SDL crash
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  local result = testCasesForPolicySDLErrorsStops:CheckSDLShutdown(self)
  if (result == false) then
    self:FailTestCase("Error: SDL doesn't stop.")
  end
end

function Test:TestStep_CheckSDLLogError()
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