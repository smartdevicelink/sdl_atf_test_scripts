---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SubscribeVehicleData] General ResultCode and the individual result codes for a part of parameters disallowed by Policies
-- [Mobile API] [GENIVI] SubscribeVehicleData request/response
-- [HMI API] [GENIVI] VehicleInfo.SubscribeVehicleData request/response
--
-- Description:
-- SDL must:
-- - transfer the allowed params of SubscribeVehicleData to HMI
-- - get the response with <general_result_code_from_HMI> and allowed parameters with their correponding individual-result-codes from HMI
-- - respond to mobile application with "ResultCode: <general-result-code_from_HMI>, success: <applicable flag>"
-- + "info" parameter(listing the params disallowed by policies and the information about allowed params processing)
-- + allowed parameters and their correponding individual result codes got from HMI and all disallowed parameters
-- with the individual resultCode of DISALLOWED for NOT-allowed params of SubscribeVehicleData
-- In case:
-- - SubscribeVehicleData is allowed by policies with less than supported by protocol parameters
-- - AND the app assigned with such policies requests SubscribeVehicleData with one and-or more allowed params
-- and with one and-or more NOT-allowed params
--
-- Preconditions:
-- 1. Application with <appID> is registered on SDL.
-- 2. Specific permissions are assigned for <appID> with SubscribeVehicleData
-- Steps:
-- 1. Send SubscribeVehicleData RPC App -> SDL
-- 2. Verify status of response
--
-- Expected result:
-- SDL -> App:
-- General: success: true, resultCode: SUCCESS
-- Individual:
-- - for allowed: dataType: <parameter>, resultCode: SUCCESS
-- - for disallowed: dataType: <parameter>, resultCode: DISALLOWED
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local functions ]]
local function UpdatePolicy()
  local PermissionForSubscribeVehicleData =
  [[
  "SubscribeVehicleData": {
    "hmi_levels": ["BACKGROUND",
    "FULL",
    "LIMITED",
    "NONE"],
    "parameters": ["rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "speed"]
  }
  ]].. ", \n"
  local PermissionForUnsubscribeVehicleData =
  [[
  "UnsubscribeVehicleData": {
    "hmi_levels": ["BACKGROUND",
    "FULL",
    "LIMITED",
    "NONE"],
    "parameters": ["rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "speed"]
  }
  ]].. ", \n"

  local PermissionLinesForBase4 = PermissionForSubscribeVehicleData..PermissionForUnsubscribeVehicleData
  local PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, nil, nil, {"SubscribeVehicleData","UnsubscribeVehicleData"})
  testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)
end
UpdatePolicy()

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
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
function Test:TestStep_SubscribeVehicleData()
  local corId = self.mobileSession:SendRPC("SubscribeVehicleData",
    {
      speed = true,
      rpm = true,
      fuelLevel = true
    })
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
    {
      speed = true,
      rpm = true,
      fuelLevel = true
    })
  :Do(function(_, d)
      self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS",
        {
          speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS"},
          rpm = {dataType = "VEHICLEDATA_RPM", resultCode = "SUCCESS"},
          fuelLevel = {dataType = "VEHICLEDATA_FUELLEVEL", resultCode = "SUCCESS"},
        })
    end)
  self.mobileSession:ExpectResponse(corId,
    {
      success = true,
      resultCode = "SUCCESS",
      speed = { dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS" },
      rpm = { dataType = "VEHICLEDATA_RPM", resultCode = "SUCCESS" },
      fuelLevel = { dataType = "VEHICLEDATA_FUELLEVEL", resultCode = "SUCCESS" }
    })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end
