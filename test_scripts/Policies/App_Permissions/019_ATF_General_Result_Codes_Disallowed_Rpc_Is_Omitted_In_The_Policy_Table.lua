---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GeneralResultCodes] DISALLOWED: RPC is omitted in the PolicyTable group(s) assigned to the application
--
-- Description:
-- SDL must return DISALLOWED resultCode and success = "false" to the RPC requested by the application
-- in case the successfully registered application sends an RPC that is NOT included (omitted)
-- in the PolicyTable group(s) assigned to the application
--
-- Preconditions:
-- 1. Application with <appID> is registered on SDL.
-- 2. Policy Table contains section "functional_groupings", where in group that assigned for app
-- PRC is not specified
-- Steps:
-- 1. Send RPC App -> SDL
-- 2. Verify status of response
--
-- Expected result:
-- SDL -> App: RPC (DISALLOWED, success: "false")
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/App_Permissions/DisallowedRPCs.json")

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
function Test:SendRPC_SubscribeVehicleData()
  local corId = self.mobileSession:SendRPC("SubscribeVehicleData", {})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_Alert()
  local corId = self.mobileSession:SendRPC("Alert", {})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_SendLocation()
  local corId = self.mobileSession:SendRPC("SendLocation", {})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_Show()
  local corId = self.mobileSession:SendRPC("Show", {mainField1 = "mainField1"})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_AlertManeuver()
  local corId = self.mobileSession:SendRPC("AlertManeuver", {})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_DiagnosticMessage()
  local corId = self.mobileSession:SendRPC("DiagnosticMessage",{
        targetID = 42,
        messageLength = 8,
        messageData = {1}
})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end
