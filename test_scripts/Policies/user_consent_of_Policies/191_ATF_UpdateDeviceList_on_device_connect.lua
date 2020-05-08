---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [UpdateDeviceList] sending to HMI
-- [HMI API] BasicCommunication.UpdateDeviceList request/response
--
-- Description:
-- UpdateDeviceList request from SDl to HMI upon new device connection
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Close current connection
-- 2. Performed steps:
-- Connect device
--
-- Expected result:
-- SDL sends UpdateDeviceList to HMI right after new device connects over WiFi
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require ('user_modules/shared_testcases/commonPreconditions')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
require('mobile_session')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:UpdateDeviceList_on_device_connect()
  self:connectMobile()
  if utils.getDeviceTransportType() == "WIFI" then
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
  commonTestCases:DelayedExp(60*1000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
