---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GetVehicleData] app sends NOT-allowed parameters by Policies only
--
-- Description:
-- SDL must:
-- - respond to mobile app with "DISALLOWED, success: false"
-- SDL must NOT:
-- - send to HMI GetVehicleData_request
-- In case:
-- - GetVehicleData is allowed by policies with less than supported by protocol parameters
-- - and the app assigned with such policies requests GetVehicleData with NOT-allowed params only
--
-- Preconditions:
-- 1. Application with <appID> is registered on SDL.
-- 2. Specific permissions are assigned for <appID> with GetVehicleData
-- Steps:
-- 1. Send GetVehicleData RPC App -> SDL with not specified parameters
-- 2. Verify status of response
--
-- Expected result:
-- SDL -> App: success: false, resultCode: DISALLOWED
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
    "parameters": ["gps", "speed"]
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
function Test:TestStep_GetVehicleData_DISALLOWED()
  local corId = self.mobileSession:SendRPC("GetVehicleData",
    {
      fuelLevel_State = true,
      instantFuelConsumption = true,
    })
  EXPECT_HMICALL("VehicleInfo.GetVehicleData")
  :Times(0)
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:TestStep_GetVehicleData_SUCCESS()
  local corId = self.mobileSession:SendRPC("GetVehicleData",
    {
      speed = true,
      fuelLevel_State = true,
      instantFuelConsumption = true,
    })
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", { speed = true })
  :Do(function(_,data)
      self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"speed":55.5}')
    end)
  self.mobileSession:ExpectResponse(corId)
  :Do(function(_,data)
      if (data.payload.resultCode == "DISALLOWED") then
        self:FailTestCase("GetVehicleData should not be DISALLOWED by policy")
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end
