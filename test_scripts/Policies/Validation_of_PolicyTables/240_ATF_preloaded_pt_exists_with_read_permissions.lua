---------------------------------------------------------------------------------------------
-- Description:
-- Behavior of SDL during start SDL with Preloaded PT file with read permissions
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Create correct PreloadedPolicyTable file with read permissions
-- Start SDL

-- Requirement summary:
-- [Policy] Preloaded PT exists at the path defined in .ini file WITH "read" permissions
--
-- Expected result:
-- SDL started successfully
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Local variables ]]
local preloaded_pt_file_name = "sdl_preloaded_pt.json"
local GRANT = "+"

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2
commonPreconditions:BackupFile(preloaded_pt_file_name)

--[[ General Settings for configuration ]]
Test = require('connecttest')
require("user_modules/AppTypes")

--[[ Local functions ]]
function Test.change_read_permissions_from_preloaded_pt_file(sign)
  os.execute(table.concat({"chmod -f a", sign, "r ", config.pathToSDL, preloaded_pt_file_name}))
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_ChangePermissionsPreloaded()
  StopSDL()
  commonSteps:DeletePolicyTable()
  self.change_read_permissions_from_preloaded_pt_file(GRANT)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test.TestStep_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test.TestStep_checkSdl_Running()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose"):Times(0)
end

function Test:TestStep_CheckSDLLogError()
  --function will return true in case error is observed in smartDeviceLink.log
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized.")
  if (result == true) then
    self:FailTestCase("Error: message 'Policy table is not initialized.' is not observed in smartDeviceLink.log.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop()
  StopSDL()
end
