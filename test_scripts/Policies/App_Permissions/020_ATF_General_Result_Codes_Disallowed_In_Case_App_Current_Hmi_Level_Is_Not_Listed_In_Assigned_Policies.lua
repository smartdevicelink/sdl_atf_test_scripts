---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GeneralResultCodes] DISALLOWED in case app's current HMI Level is not listed in assigned policies
--
-- Description:
-- SDL must return DISALLOWED resultCode and success = "false" to the RPC requested by the application
-- in case Policy Table doesn't contain current application's HMILevel
-- defined in Policy Table "functional_groupings" section for a specified RPC
--
-- Preconditions:
-- 1. Application with <appID> is registered on SDL.
-- 2. Current HMILevel for application is HMILevel_1
-- 3. Policy Table contains section "functional_groupings",
-- in which for a specified PRC there're defined HMILevels: HMILevel_2, HMILevel_3
-- Steps:
-- 1. Send RPC App -> SDL
-- 2. Verify status of respo
--
-- Expected result:
-- SDL -> App: RPC (DISALLOWED, success: "false")
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local testCasesForPolicyAppIdManagament = require("user_modules/shared_testcases/testCasesForPolicyAppIdManagament")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondtion_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:UpdatePolicy()
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/App_Permissions/ptu_021.json")
  --testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/ptu_general_steal_focus_false.json")

end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:SendRPC_AddCommand()
  local corId = self.mobileSession:SendRPC("AddCommand", {cmdID = 1,menuParams = {menuName = "Options"}, vrCommands = {"Options"} })
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_AddSubMenu()
  local corId = self.mobileSession:SendRPC("AddSubMenu", {menuID = 1000, position = 500, menuName ="SubMenupositive"})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_Alert()
  local corId = self.mobileSession:SendRPC("Alert", {alertText1 = "alertText1"})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_Show()
  local corId = self.mobileSession:SendRPC("Show", {mainField1 = "mainField1"})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_SystemRequest()
  local corId = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

function Test:SendRPC_UnregisterAppInterface()
  local corId = self.mobileSession:SendRPC("UnregisterAppInterface",{})
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
