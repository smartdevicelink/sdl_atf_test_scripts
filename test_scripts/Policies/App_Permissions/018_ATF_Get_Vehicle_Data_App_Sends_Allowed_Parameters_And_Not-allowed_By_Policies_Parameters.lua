---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GetVehicleData] app sends allowed parameters and NOT-allowed by Policies parameters
--
-- Description:
-- SDL must:
-- - transfer to HMI GetVehicleData with allowed params only
-- - ignore the NOT-allowed params
-- - respond to mobile app with "ResultCode: <applicable-result-code>,
-- success: <applicable flag>" + "info" parameter listing the params disallowed by policies
-- In case:
-- - GetVehicleData is allowed by policies with less than supported by protocol parameters
-- - the app assigned with such policies requests GetVehicleData with one and-or more allowed params
-- and with one and-or more NOT-allowed params
--
-- Preconditions:
-- 1. Application with <appID> is registered on SDL.
-- 2. Specific permissions are assigned for <appID> with GetVehicleData
-- Steps:
-- 1. Send GetVehicleData RPC App -> SDL
-- 2. Verify status of response
--
-- Expected result:
-- SDL -> HMI: Only allowed parameters
-- SDL -> App: "success: true, resultCode: SUCCESS, + "info" parameter listing the params disallowed by policies
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local functions ]]
local function UpdatePolicy()
  local PermissionForGetVehicleData =
  [[
  "GetVehicleData": {
    "hmi_levels": ["BACKGROUND",
    "FULL",
    "LIMITED",
    "NONE"],
    "parameters": ["speed", "rpm", "fuelLevel"]
  }
  ]].. ", \n"

  local PermissionLinesForBase4 = PermissionForGetVehicleData
  local PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, nil, nil, {"GetVehicleData"})
  testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)
end
UpdatePolicy()

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_GetVehicleData()
  local corId = self.mobileSession:SendRPC("GetVehicleData",
    {
      gps = true,
      speed = true,
      rpm = true,
      fuelLevel = true,
      fuelLevel_State = true,
      instantFuelConsumption = true,
      externalTemperature = true,
      vin = true,
      prndl = true,
      tirePressure = true,
      odometer = true,
      beltStatus = true,
      bodyInformation = true,
      deviceStatus = true,
      driverBraking = true,
      wiperStatus = true,
      headLampStatus = true,
      engineTorque = true,
      accPedalPosition = true,
      steeringWheelAngle = true
    })

  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{})
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, "VehicleInfo.GetVehicleData", "SUCCESS",
        {
          speed = 101.00,
          rpm = 12345,
          fuelLevel = 20.00
        })
    end)
  self.mobileSession:ExpectResponse(corId,
    {
      success = true,
      resultCode = "SUCCESS",
      speed = 101.00,
      rpm = 12345,
      fuelLevel = 20.00,
      info = "'accPedalPosition', 'beltStatus', 'bodyInformation', 'deviceStatus', 'driverBraking', 'engineTorque', 'externalTemperature', 'fuelLevel_State', 'gps', 'headLampStatus', 'instantFuelConsumption', 'odometer', 'prndl', 'steeringWheelAngle', 'tirePressure', 'vin', 'wiperStatus' disallowed by policies."
    })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
