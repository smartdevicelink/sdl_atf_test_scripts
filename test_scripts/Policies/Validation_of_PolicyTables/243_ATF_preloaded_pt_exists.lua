---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policy] Upon startup SDL must check PreloadPT existance
-- [INI file] [Policy]: PreloadedPT json location
--
-- Description:
-- Behavior of SDL during start SDL in case when PreloadedPT exist at the path defined in .ini file
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Change path to PreloadedPolicyTable file defined in .ini file
-- Create correct PreloadedPolicyTable file at the path defined in .ini file
-- Start SDL
--
-- Expected result:
-- SDL started successfully
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local sdl = require('modules/SDL')

--[[ Local Functions ]]
local function checkSDLStatus(test, expStatus)
  local actStatus = sdl:CheckStatusSDL()
  print("SDL status: " .. tostring(actStatus))
  if actStatus ~= expStatus then
    local msg = "Expected SDL status: " .. expStatus .. ", actual: " .. actStatus
    test:FailTestCase(msg)
  end
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2
config.ExitOnCrash = false

--[[ Local variables ]]
local PPT_FILE_NAME = "sdl_preloaded_pt.json"

--[[ General configuration parameters ]]
Test = require('connecttest')
require("user_modules/AppTypes")

--[[ Local functions ]]
function Test.create_path_to_preloaded_pt(path)
  local full_path = config.pathToSDL .. path
  os.execute("mkdir " .. full_path)
  return table.concat({full_path, "/", PPT_FILE_NAME})
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_StopSDL()
  StopSDL(self)
end

function Test.Precondition_Change_bin_files()
  commonSteps:DeletePolicyTable()
  commonPreconditions:BackupFile(PPT_FILE_NAME)
  os.execute( " rm -f " .. config.pathToSDL .. PPT_FILE_NAME)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test.TestStep_start_sdl()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 5")
end

function Test:TestStep_CheckSDLStops()
  checkSDLStatus(self, sdl.STOPPED)
end

function Test:TestStep_CheckSDLLogError()
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized.")
  if (result == false) then
    self:FailTestCase("Error: message 'Policy table is not initialized.' is not observed in smartDeviceLink.log.")
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("BasicCommunication.OnSDLClose")
  if (result == false) then
    self:FailTestCase("Error: 'BasicCommunication.OnSDLClose' is observed in smartDeviceLink.log.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
