---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md
-- Description:
-- Precondition:
-- 1) App registered and activated, OnHMIStatus(FULL)
-- 2) AddCommand RPC added to two function groups (Base-4, NewTestCaseGroup)
-- 3) RPC not needs protection, encryption_required parameters to App within app_policies = nil and to the
--    appropriate function_group (Base-4) = nil, (NewTestCaseGroup) = nil
-- In case:
-- 1) During PTU parameters updated: function_group (NewTestCaseGroup): nil -> true
-- 2) RPC service 7 is started in protected mode
-- 3) mobile application sends encrypted RPC request (AddCommand) to SDL
-- SDL does:
-- 1) resend this request (AddCommand) RPC to HMI
-- 2) HMI sends (AddCommand) RPC response with resultCode = SUCCESS to SDL
-- SDL does:
-- 1) send encrypted response (AddCommand) to mobile application with result code “Success”
-- 2) send unencrypted notification (OnHashChange)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Security/RPCMessageProtection/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local grpData = {
  rpcs = {
    AddCommand = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
    }
  }
}

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.functional_groupings["NewTestCaseGroup"] = grpData
  pTbl.policy_table.app_policies["spt"].groups = { "Base-4", "NewTestCaseGroup" }
  pTbl.policy_table.app_policies["spt"].encryption_required = nil
  pTbl.policy_table.functional_groupings["Base-4"].encryption_required = nil
  pTbl.policy_table.functional_groupings["NewTestCaseGroup"].encryption_required = nil
end

local function ptUpdateNewParam(pTbl)
  ptUpdate(pTbl)
  pTbl.policy_table.functional_groupings["NewTestCaseGroup"].encryption_required = true
end

local function unprotectedRpcInUnprotectedModeEncryptedRequired()
  local cid = common.getMobileSession():SendRPC("AddCommand", common.getAddCommandParams(2))
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "ENCRYPTION_NEEDED" })
end

local function protectedRpcInProtectedModeEncryptedRequired()
  local cid = common.getMobileSession():SendEncryptedRPC("AddCommand", common.getAddCommandParams(2))
  common.getHMIConnection():ExpectRequest("UI.AddCommand", common.getAddCommandParams(2))
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)
runner.Step("Unprotected RPC in unprotected mode, Encrypted not required",
  common.unprotectedRpcInUnprotectedModeSuccess)
runner.Step("Register App_2", common.registerApp, { 2 })
runner.Step("Policy Table Update", common.policyTableUpdate, { ptUpdateNewParam })

runner.Title("Test")
runner.Step("Unprotected RPC in unprotected mode, Encrypted required", unprotectedRpcInUnprotectedModeEncryptedRequired)
runner.Step("Start RPC Service protected", common.switchRPCServiceToProtected)
runner.Step("Protected RPC in protected mode", protectedRpcInProtectedModeEncryptedRequired)

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
