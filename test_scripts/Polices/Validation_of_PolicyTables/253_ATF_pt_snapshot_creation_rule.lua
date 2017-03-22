---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] PTS creation rule
--
-- Check creation of PT snapshot
-- 1. Used preconditions:
-- Do not start default SDL
-- 2. Performed steps:
-- Set correct PathToSnapshot path in INI file
-- Start SDL
-- Initiate PT snapshot creation
--
-- Expected result:
-- SDL must copy the Local Policy Table into memory and remove "messages" sub-section from "consumer_friendly_messages" section and store information as PT snapshot
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local json = require("modules/json")
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start]]
config.defaultProtocolVersion = 2
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General configuration parameters ]]
Test = require('connecttest')
local config = require('config')
require('user_modules/AppTypes')
require('cardinalities')

--[[ Local Variables ]]
local CORRECT_LINUX_PATH_TO_POLICY_SNAPSHOT_FILE = "sdl_snapshot.json"
local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")

--[[ Local Functions ]]
function Test.checkPtsFile()
  local file = io.open(SystemFilesPath.."/"..CORRECT_LINUX_PATH_TO_POLICY_SNAPSHOT_FILE, "r")
  if file then
    local json_data = file:read("*a")
    file:close()
    local data = json.decode(json_data)
    local result = true
    if data.policy_table.consumer_friendly_messages then
      for key, _ in pairs(data.policy_table.consumer_friendly_messages) do
        if key == "messages" then
          commonFunctions:userPrint(31, "Test failed: PT snapshot contains sub-section \"messages\" in \"consumer_friendly_messages\" section")
          result = false
        end
      end
    end
    return result
  else
    commonFunctions:userPrint(31, "Test failed: PT snapshot not found")
    return false
  end
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Test()
  if not self:checkPtsFile() then
    self:FailTestCase("Test is failed. See prints")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test