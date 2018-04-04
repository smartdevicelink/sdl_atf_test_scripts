---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [UpdateDeviceList] isSDLAllowed:false
-- [HMI API] BasicCommunication.UpdateDeviceList request/response
--
-- Description:
-- SDL behavior if DataConsent status was never asked for the corresponding device.
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Close current connection
-- 2. Performed steps:
-- Connect device
--
-- Expected result:
-- PoliciesManager must provide "isSDLAllowed:false" param of "DeviceInfo" struct ONLY when sending "UpdateDeviceList" RPC to HMI
---------------------------------------------------------------------------------------------
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
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", {
      deviceList = {
        {
          id = utils.getDeviceMAC(),
          isSDLAllowed = false,
          name = utils.getDeviceName(),
          transportType = "WIFI"
    }}})
  :Do(function(_,data)
      if data.params.deviceList[1].isSDLAllowed ~= false then
        commonFunctions:userPrint(31, "Error: SDL should not be allowed for a new unconsented device")
      else
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
