------------- --------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] With data consent, assign "default" policies to the application
-- which appID does not exist in LocalPT
--
-- Description:
-- SDL should assign "default" permissions in case the application registers
-- (sends RegisterAppInterface request) with the appID that does not exist in Local Policy Table,
-- and Data Consent has been received for the device this application registers from.
--
-- Preconditions:
-- 1. appID="123_xyz" and "456_abc" are not registered to SDL yet
-- 2. Register new application with appID="456_abc"
-- 3. Activate appID="456_abc". Device is consented
-- Steps:
-- 1. Register new application with appID="123_xyz"
-- 2. Send "PutFile" RPC in order to verify that "default" permissions are assigned
-- This RPC is allowed.
-- 3. Verify RPC's respond status
-- 4. Send "GetVehicleData". This RPC is not allowed.
-- 5. Verify RPC's respond status
--
-- Expected result:
-- Status of response: success = true, resultCode = "SUCCESS" for PutFile
-- Status of response: success = false, resultCode = "DISALLOWED" for GetVehicleData
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PutFile_SUCCESS()
  local corId = self.mobileSession:SendRPC("PutFile", {syncFileName ="icon.png", fileType ="GRAPHIC_PNG"}, "files/icon.png")
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
end

function Test:TestStep_GetVehicleData_DISALLOWED()
  local cid = self.mobileSession:SendRPC("GetVehicleData",{gps = true})
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{}):Times(0)
  EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
