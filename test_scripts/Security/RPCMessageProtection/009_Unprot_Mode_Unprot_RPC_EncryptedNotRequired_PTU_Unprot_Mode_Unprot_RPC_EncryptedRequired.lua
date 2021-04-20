---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md
-- Description:
-- Precondition:
-- 1) App registered and activated, OnHMIStatus(FULL)
-- In case:
-- 1) During PTU parameters updated: app_policies: false -> true, function_group (Base-4): false -> true
-- 2) mobile application sends unencrypted RPC request (AddCommand) to SDL
-- SDL does:
-- 1) send response (success = false, resultCode = "ENCRYPTION_NEEDED") to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Security/RPCMessageProtection/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies["spt"].encryption_required = false
  pTbl.policy_table.functional_groupings["Base-4"].encryption_required = false
end

local function ptUpdateNewParam(pTbl)
  pTbl.policy_table.app_policies["spt"].encryption_required = true
  pTbl.policy_table.functional_groupings["Base-4"].encryption_required = true
end

local function unprotectedRpcInUnprotectedModeEncryptedRequired()
  local cid = common.getMobileSession():SendRPC("AddCommand", common.getAddCommandParams(2))
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "ENCRYPTION_NEEDED" })
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
runner.Step("Protected RPC in unprotected mode", unprotectedRpcInUnprotectedModeEncryptedRequired)

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
