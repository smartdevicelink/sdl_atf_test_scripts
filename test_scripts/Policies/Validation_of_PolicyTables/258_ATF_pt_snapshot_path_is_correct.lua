---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] Name defined in PathToSnapshot of .ini file is correct for the specific OS
-- [INI file] [PolicyTableUpdate] PTS snapshot storage on a file system
--
-- Behavior of SDL during start SDL with correct path to PathToSnapshot in INI file for the specific OS (Linux)
-- 1. Used preconditions:
-- Do not start default SDL
-- 2. Performed steps:
-- Set correct PathToSnapshot path in INI file for the specific OS (Linux)
-- Start SDL
--
-- Expected result:
-- SDL must continue working
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local SDL = require('modules/SDL')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()


--[[ General configuration parameters ]]
Test = require('connecttest')
require('user_modules/AppTypes')

function Test.checkSdl()
  local status = SDL:CheckStatusSDL()
  if status ~= SDL.RUNNING then
    commonFunctions:userPrint(31, "Test failed: SDL is not running with correct PathToSnapshot in INI file")
    return false
  end
  return true
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:TestStep_Check_snapshot_created()
  local PathToSnapshot = commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local result = commonFunctions:File_exists(SystemFilesPath.."/"..PathToSnapshot)
  if (result == false) then
    self:FailTestCase("ERROR: "..SystemFilesPath.."/"..PathToSnapshot.." doesn't exist!")
  end
end

function Test:TestStep_CheckSDL_Running()
  os.execute("sleep 3")
  if not self.checkSdl() then
    self:FailTestCase()
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
