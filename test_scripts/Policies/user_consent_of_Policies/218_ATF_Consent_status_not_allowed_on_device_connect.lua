---------------------------------------------------------------------------------------------
-- Requirement summary:
--    [DeviceConsent] DataConsent status for each device is written in LocalPT
--
-- Description:
--     Providing the device`s DataConsent status (not allowed) to HMI upon device connection to SDL
--     1. Used preconditions:
--        Delete files and policy table from previous ignition cycle if any
--     2. Performed steps:
--        Connect device
--
-- Expected result:
--     SDL/PoliciesManager must provide the device`s DataConsent status (not allowed) to HMI upon device`s connection->
--     SDL must request DataConsent status of the corresponding device from the PoliciesManager
-------------------------------------------------------------------------------------------------
--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local utils = require ('user_modules/utils')
require('user_modules/AppTypes')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Check_device_connects_as_not_consented()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
  {
    deviceList = {
      {
        id = utils.getDeviceMAC(),
        isSDLAllowed = false,
        name = utils.getDeviceName(),
        transportType = "WIFI"
      }
    }
  }
  ):Do(function(_,data)
  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :Times(AtLeast(1))
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
