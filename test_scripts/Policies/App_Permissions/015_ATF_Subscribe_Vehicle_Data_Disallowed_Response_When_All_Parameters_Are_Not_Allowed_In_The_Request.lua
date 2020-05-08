---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SubscribeVehicleData] DISALLOWED response when all parameters are not allowed in the request
-- [Mobile API] [GENIVI] SubscribeVehicleData request/response
-- [HMI API] [GENIVI] VehicleInfo.SubscribeVehicleData request/response
--
-- Description:
-- SDL must:
-- - not send anything to HMI,
-- - AND return the individual results of DISALLOWED to response to mobile app + "ResultCode:DISALLOWED, success: false"
-- In case:
-- - SubscribeVehicleData RPC is allowed by policies with less than supported by protocol parameters
-- - AND the app assigned with such policies requests SubscribeVehicleData with one and-or more NOT-allowed params only
--
-- Preconditions:
-- 1. Application with <appID> is registered on SDL.
-- 2. Specific permissions are assigned for <appID> with SubscribeVehicleData
-- Steps:
-- 1. Send SubscribeVehicleData RPC App -> SDL with not specified parameters
-- 2. Verify status of response
--
-- Expected result:
-- SDL -> App:
-- General: success: false, resultCode: DISALLOWED
-- Individual: dataType: <parameter>, resultCode: DISALLOWED
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
--testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/App_Permissions/ptu_015.json")

--[[ Local functions ]]
local function UpdatePolicy()
  local PermissionForSubscribeVehicleData =
  [[
  "SubscribeVehicleData": {
    "hmi_levels": ["BACKGROUND",
    "FULL",
    "LIMITED",
    "NONE"],
    "parameters": []
  }
  ]].. ", \n"
  local PermissionForUnsubscribeVehicleData =
  [[
  "UnsubscribeVehicleData": {
    "hmi_levels": ["BACKGROUND",
    "FULL",
    "LIMITED",
    "NONE"],
    "parameters": []
  }
  ]].. ", \n"

  local PermissionLinesForBase4 = PermissionForSubscribeVehicleData..PermissionForUnsubscribeVehicleData
  local PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, nil, nil, {"SubscribeVehicleData","UnsubscribeVehicleData"})
  testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt(PTName)
end
UpdatePolicy()

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
      fuelLevel_State = true,
      instantFuelConsumption = true,
    })
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData") :Times(0)
  self.mobileSession:ExpectResponse(corId, { success = false, resultCode = "DISALLOWED" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end
