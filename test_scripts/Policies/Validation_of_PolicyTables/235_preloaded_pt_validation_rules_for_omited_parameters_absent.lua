---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: PreloadedPolicyTable: Validation rules for omited parameters - do NOT exist
--
-- Description:
-- Valid elements in preloaded_pt are checked in 008_ATF_P_TC_PTS_Creation_rule.lua
-- As precondition preloaded_pt should have only required and optional parameters.
-- Behavior of SDL during start SDL in case when PreloadedPT has no omited parameters
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Create PreloadedPolicyTable file with couple omited parameters
-- Start SDL
--
-- Expected result:
-- SDL continue working as assigned
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require("user_modules/AppTypes")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test.TestStep_checkSdl_Running()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose"):Times(0)
  os.execute("sleep 3")
end

function Test:TestStep_CheckSDLLogError()
  --function will return true in case error is observed in smartDeviceLink.log
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized.")
  if (result == true) then
    self:FailTestCase("Error: message 'Policy table is not initialized.' should not observed in smartDeviceLink.log.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end
