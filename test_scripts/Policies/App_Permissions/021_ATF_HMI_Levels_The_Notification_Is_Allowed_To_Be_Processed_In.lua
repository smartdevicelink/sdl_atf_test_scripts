---------------------------------------------------------------------------------------------
-- Requirement summary:
-- HMI Levels the notification is allowed to be processed in
-- [Mobile API] OnCommand notification
--
-- Description:
-- SDL must not send/ transfer (in case got from HMI) notification to mobile application,
-- in case Policy Table doesn't contain current application's HMILevel
-- defined in Policy Table "functional_groupings" section for a specified notification
--
-- Preconditions:
-- 1. Application with <appID> is registered on SDL.
-- 2. Current HMILevel for application is HMILevel_1
-- 3. Policy Table contains section "functional_groupings",
-- in which for a specified PRC there're defined HMILevels: HMILevel_2, HMILevel_3
-- Steps:
-- 1. Send notification HMI -> SDL
-- 2. Verify SDL not transfer notification to app
--
-- Expected result:
-- SDL -> App: There is no notification
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local utils = require ('user_modules/utils')

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
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:SendRPC_AddCommand()
  local corId = self.mobileSession:SendRPC("AddCommand", {cmdID = 1,menuParams = {menuName = "Options"}, vrCommands = {"Options"} })
  EXPECT_HMICALL("UI.AddCommand"):Times(0)
  EXPECT_HMICALL("VR.AddCommand"):Times(0)
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
  commonTestCases:DelayedExp(10000)
end

function Test:SendRPC_AddSubMenu()
  local corId = self.mobileSession:SendRPC("AddSubMenu", {menuID = 1000, position = 500, menuName ="SubMenupositive"})
  EXPECT_HMICALL("UI.AddSubMenu"):Times(0)
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
  commonTestCases:DelayedExp(10000)
end

function Test:SendRPC_Alert()
  local corId = self.mobileSession:SendRPC("Alert", {alertText1 = "alertText1"})
  EXPECT_HMICALL("UI.Alert"):Times(0)
  EXPECT_HMICALL("TTS.Speak"):Times(0)
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
  commonTestCases:DelayedExp(10000)
end

function Test:SendRPC_Show()
  local corId = self.mobileSession:SendRPC("Show", {mainField1 = "mainField1"})
  EXPECT_HMICALL("UI.Show"):Times(0)
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
  commonTestCases:DelayedExp(10000)
end

function Test:SendRPC_SystemRequest()
  local corId = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"})
  EXPECT_HMICALL("BasicCommunication.SystemRequest"):Times(0)
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
  commonTestCases:DelayedExp(10000)
end

function Test:SendRPC_UnregisterAppInterface()
  local corId = self.mobileSession:SendRPC("UnregisterAppInterface",{})
  EXPECT_HMICALL("BasicCommunication.OnAppUnregistered"):Times(0)
  self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
  commonTestCases:DelayedExp(10000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
