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
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
Test =  require('user_modules/dummy_connecttest')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local utils = require ('user_modules/utils')
local hmi_values = require('user_modules/hmi_values')
local SDL = require('SDL')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[Local Functions ]]
function Test:initHMIonReady()
  local hmiParams = hmi_values.getDefaultHMITable()
  hmiParams.BasicCommunication.UpdateDeviceList = nil
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", { deviceList = { [1] = { isSDLAllowed = false } } })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(SDL.buildOptions.webSocketServerSupport == "ON" and 1 or 0)
  return self:initHMI_onReady(hmiParams)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:HMI_SDL_initialization()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
      self:initHMI():Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMIonReady():Do(function ()
              commonFunctions:userPrint(35, "HMI is ready")
            end)
        end)
    end)
end

function Test:UpdateDeviceList_on_device_connect()
  local exp = { deviceList = { [1] = { isSDLAllowed = false } } }
  if SDL.buildOptions.webSocketServerSupport == "ON" then
    exp.deviceList[2] = exp.deviceList[1]
  end
  if utils.getDeviceTransportType() == "WIFI" then
    self:connectMobile()
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", exp)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  else
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Times(0)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
