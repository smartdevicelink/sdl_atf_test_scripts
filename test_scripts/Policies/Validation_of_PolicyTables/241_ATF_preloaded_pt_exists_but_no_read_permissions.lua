---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policy] Preloaded PT exists at the path defined in .ini file but NO "read" permissions
--
-- Description:
-- Behavior of SDL during start SDL with Preloaded PT file without read permissions
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Create correct PreloadedPolicyTable file without read permissions
-- Start SDL
--
-- Expected result:
-- PolicyManager shut SDL down
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicySDLErrorsStops = require('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')
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

--[[ General Settings for configuration ]]
Test = require('connecttest')
require("user_modules/AppTypes")

--[[ Local variables ]]
local preloaded_pt_file_name = "sdl_preloaded_pt.json"
local GRANT = "+"
local REVOKE = "-"

--[[ Local functions ]]
function Test.change_read_permissions_from_preloaded_pt_file(sign)
  os.execute(table.concat({"chmod -f a", sign, "r ", config.pathToSDL, preloaded_pt_file_name}))
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Preconditions_StopSDl()
  StopSDL()
end

function Test:Precondition()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
  self.change_read_permissions_from_preloaded_pt_file(REVOKE)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test.TestStep_start_sdl()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 5")
end

function Test:TestStep_checkSdl_Stop()
  checkSDLStatus(self, sdl.STOPPED)
end

function Test:TestStep_CheckSDLLogError()
  --function will return true in case error is observed in smartDeviceLink.log
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized.")
  if (result ~= true) then
    self:FailTestCase("Error: message 'Policy table is not initialized.' is not observed in smartDeviceLink.log.")
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("BasicCommunication.OnSDLClose")
  if (result ~= true) then
    self:FailTestCase("Error: 'BasicCommunication.OnSDLClose' is not observed in smartDeviceLink.log.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test:Postcondition()
  self.change_read_permissions_from_preloaded_pt_file(GRANT)
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
