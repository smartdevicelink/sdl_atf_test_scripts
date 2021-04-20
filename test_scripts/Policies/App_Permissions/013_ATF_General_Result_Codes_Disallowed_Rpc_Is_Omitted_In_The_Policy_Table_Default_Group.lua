---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GeneralResultCodes]DISALLOWED: RPC is omitted in the PolicyTable "default" group(s) assigned to the application
--
-- Description:
-- SDL must return DISALLOWED resultCode and success = "false" to the RPC requested by the application
-- in case the successfully registered application with assigned "default" policies,
-- sends an RPC that is NOT included (omitted) in the PolicyTable "default" group(s) assigned to the application
--
-- Preconditions:
-- 1. Application with <appID> is registered on SDL.
-- 2. Default permissions are assigned for <appID>
-- 2. PRC is not specified in default permissions
-- Steps:
-- 1. Send RPC App -> SDL
-- 2. Verify status of response
--
-- Expected result:
-- SDL -> App: RPC (DISALLOWED, success: "false")
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForPolicyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local rpc = {}
rpc["AddCommand"] = {cmdID = 1, menuParams = {menuName = "Options"}, vrCommands = {"Options"}}
rpc["AddSubMenu"] = {menuID = 1000, position = 500, menuName ="SubMenupositive"}
rpc["Alert"] = {alertText1 = "alertText1"}
rpc["Show"] = {mainField1 = "mainField1"}
rpc["SystemRequest"] = {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"}


--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/App_Permissions/ptu_014.json")

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_ActivateApplication()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

-- function Test:UpdatePolicy()
-- testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/App_Permissions/ptu_014.json")
-- end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

for k, v in pairs(rpc) do
  Test["SendRPC_" .. k] = function(self)
    local corId = self.mobileSession:SendRPC(k, v)
    self.mobileSession:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED"})
  end
end

function Test:TestStep_PutFile_SUCCESS()

  local CorIdPutFile = self.mobileSession:SendRPC( "PutFile",
    { syncFileName = "action.png", fileType = "GRAPHIC_PNG", persistentFile = false, systemFile = false,},
  "files/action.png")

  EXPECT_RESPONSE(CorIdPutFile, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
