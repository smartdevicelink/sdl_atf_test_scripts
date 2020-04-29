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
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')
local hmi_values = require('user_modules/hmi_values')
local SDL = require('SDL')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Local Functions ]]
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
function Test.Postcondition_SDLStop()
  StopSDL()
end
