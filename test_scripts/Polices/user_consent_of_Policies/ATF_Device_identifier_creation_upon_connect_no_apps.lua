---------------------------------------------------------------------------------------------
-- Requirement summary:
--     [Policies] <device identifier> section creation. Connection of the new device without SDL-enabled applications
--
-- Description:
--    New device is connected over WiFi WITHOUT SDL-enabled applications
-- 1. Used preconditions:
--    SDL and HMI are running
--
-- 2. Performed steps:
--    Connect device not from LPT
--
-- Expected result:
--    SDL must add new <device identifier> section in "device_data" section
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local variables ]]
local pts_json = '/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json'

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Connect_device()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
  {
    deviceList = {
      {
        id = config.deviceMAC,
        name = "127.0.0.1",
        transportType = "WIFI",
        isSDLAllowed = false
      }
    }
  }
  ):Do(function(_,data)
  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :Times(AtLeast(1))
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Check_device_identifier_added_to_lpt()
  local is_test_fail = true
  local file = io.open(pts_json, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  local deviceIdentificatorInPTS = next(data.policy_table.device_data, nil)
  if (deviceIdentificatorInPTS == config.deviceMAC) then
    commonFunctions:userPrint(33, "device_identifier ".. deviceIdentificatorInPTS.. " section is created")
    is_test_fail = false
  end
  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
