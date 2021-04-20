---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] PreloadPT all invalid values in "RequestType" array
--
-- Description:
-- Behavior of SDL during start SDL in case when PreloadedPT has has several values in "RequestType" array and one of them is invalid
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Do not start default SDL
-- 2. Performed steps:
-- Add several values in "RequestType" array (all of them are invalid) in PreloadedPT json file
-- Start SDL with created PreloadedPT json file
--
-- Expected result:
-- SDL must shutdown
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local testCasesForPolicySDLErrorsStops = require ('user_modules/shared_testcases/testCasesForPolicySDLErrorsStops')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local sdl = require('modules/SDL')
local json = require("modules/json")

--[[ Local Functions ]]
local function checkSDLStatus(test, expStatus)
  local actStatus = sdl:CheckStatusSDL()
  print("SDL status: " .. tostring(actStatus))
  if actStatus ~= expStatus then
    local msg = "Expected SDL status: " .. expStatus .. ", actual: " .. actStatus
    test:FailTestCase(msg)
  end
end

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.ExitOnCrash = false
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ Local Variables ]]
local function update_preloaded_file()
  commonPreconditions:BackupFile("sdl_preloaded_pt.json")
  local pathToFile = config.pathToSDL .. "sdl_preloaded_pt.json"

  local file = io.open(pathToFile, "r")
  local json_data = file:read("*a")
  file:close()

  local data = json.decode(json_data)
  data.policy_table.app_policies.default.RequestType = {"IVSU","HTML"}

  local dataToWrite = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(dataToWrite)
  file:close()
end

--[[ General Settings for configuration ]]
Test = require('connecttest')
require("user_modules/AppTypes")

--[[ Preconditions ]]
function Test:Precondition_stop_sdl()
  StopSDL(self)
end

function Test.TestStep_updatePreloadedPT()
  commonSteps:DeletePolicyTable()
  commonSteps:DeleteLogsFiles()
  update_preloaded_file()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test.TestStep_start_sdl()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  os.execute("sleep 5")
end

function Test:TestStep_checkSdl_Stopped()
  checkSDLStatus(self, sdl.STOPPED)
end

function Test:TestStep_CheckSDLLogError()
  --function will return true in case error is observed in smartDeviceLink.log
  local result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("Policy table is not initialized.")
  if (result ~= true) then
    self:FailTestCase("Error: message 'Policy table is not initialized.' should be observed in smartDeviceLink.log.")
  end

  result = testCasesForPolicySDLErrorsStops.ReadSpecificMessage("BasicCommunication.OnSDLClose")
  if (result ~= true) then
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
