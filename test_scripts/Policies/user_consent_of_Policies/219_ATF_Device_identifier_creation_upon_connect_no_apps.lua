---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] <device identifier> section creation. Connection of the new device without SDL-enabled applications
--
-- Description:
-- New device is connected over WiFi WITHOUT SDL-enabled applications
-- 1. Used preconditions:
-- SDL and HMI are running
--
-- 2. Performed steps:
-- Connect device not from LPT
--
-- Expected result:
-- SDL must add new device in deviceList of BasicCommunication.UpdateDeviceList
---------------------------------------------------------------------------------------------
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

--[[ Local Variables ]]
local hmiParams = hmi_values.getDefaultHMITable()
local vin = hmiParams.VehicleInfo.GetVehicleData.params.vin

--[[ Local Functions ]]
function Test:initHMIonReady()
  hmiParams.BasicCommunication.UpdateDeviceList = nil
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", {
    deviceList = {
      [1] = {
        id = utils.buildDeviceMAC("WS"),
        isSDLAllowed = false
      }
    }
  })
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
  local exp = {
    deviceList = {
      [1] = {
        id = utils.buildDeviceMAC("TCP", { host = config.mobileHost, port = config.mobilePort }),
        isSDLAllowed = false
      }
    }
  }
  if SDL.buildOptions.webSocketServerSupport == "ON" then
    table.insert(exp.deviceList, 1, {
      id = utils.buildDeviceMAC("WS"),
      isSDLAllowed = false
    })
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
