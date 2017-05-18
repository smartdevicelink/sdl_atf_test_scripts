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

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Local functions ]]
local function UpdatePolicy()
  local PermissionForAddCommand =
  [[
  "AddCommand": { "hmi_levels": ["BACKGROUND", "NONE"] }
  ]].. ", \n"
  local PermissionForAddSubMenu =
  [[
  "AddSubMenu": { "hmi_levels": ["BACKGROUND", "NONE"] }
  ]].. ", \n"
  local PermissionForAlert =
  [[
  "Alert": { "hmi_levels": ["BACKGROUND", "NONE"] }
  ]].. ", \n"
  local PermissionForShow =
  [[
  "Show": { "hmi_levels": ["BACKGROUND", "NONE"] }
  ]].. ", \n"
  local PermissionForSystemRequest =
  [[
  "SystemRequest": { "hmi_levels": ["BACKGROUND", "NONE"] }
  ]].. ", \n"
  local PermissionForUnregisterAppInterface =
  [[
  "UnregisterAppInterface": { "hmi_levels": ["BACKGROUND", "NONE"] }
  ]].. ", \n"

  local PermissionLinesForBase4 = PermissionForAddCommand..PermissionForAddSubMenu..PermissionForAlert..PermissionForShow ..PermissionForSystemRequest..PermissionForUnregisterAppInterface
  local PTName = testCasesForPolicyTable:createPolicyTableFile_temp(PermissionLinesForBase4, nil, nil, {"AddCommand", "AddSubMenu", "Alert", "Show", "SystemRequest", "UnregisterAppInterface"})
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
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
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

return Test
