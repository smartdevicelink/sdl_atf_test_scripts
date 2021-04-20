---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md
-- Description:
-- Precondition:
-- 1) App registered and activated, OnHMIStatus(FULL)
-- 2) RPC not needs protection, encryption_required parameters to App within app_policies = true and to the
--    appropriate function_group (Base-4) = true
-- In case:
-- 1) The mobile application sends unencrypted RPC request (AddCommand) to SDL
-- SDL does:
-- 1) send response (success = false, resultCode = "ENCRYPTION_NEEDED") to App
-- In case:
-- 2) During PTU updating parameters app_policies = false, function_group (Base-4) = false, encryption_required
-- 2.1) mobile application sends unencrypted RPC request (AddCommand) to SDL
-- SDL does:
-- 1) resend this request (AddCommand) RPC to HMI
-- 2) HMI sends (AddCommand) RPC response with resultCode = SUCCESS to SDL
-- SDL does:
-- 1) send unencrypted response (AddCommand) to mobile application with result code “Success”
-- 2) send unencrypted notification (OnHashChange)
-- In case:
-- 3) Unexpected disconnect/IGN_OFF and Reconnect/IGN_ON are performed
-- 3.1) App registered and activated, OnHMIStatus(FULL)
-- 3.2) mobile application sends unencrypted RPC request (AddCommand) to SDL
-- SDL does:
-- 1) resend this request (AddCommand) RPC to HMI
-- 2) HMI sends (AddCommand) RPC response with resultCode = SUCCESS to SDL
-- SDL does:
-- 1) send unencrypted response (AddCommand) to mobile application with result code “Success”
-- 2) send unencrypted notification (OnHashChange)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Security/RPCMessageProtection/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [001] = { a = true, f = true },
  [002] = { a = nil, f = true }
}

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies["spt"].encryption_required = false
  pTbl.policy_table.functional_groupings["Base-4"].encryption_required = false
end

local function unprotectedRpcInUnprotectedModeEncryptedRequired()
  local cid = common.getMobileSession():SendRPC("AddCommand", common.getAddCommandParams(2))
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "ENCRYPTION_NEEDED" })
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. string.format("%03d", n) .. "]")
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Preloaded update", common.updatePreloadedPT, { tc.a, tc.f })
  runner.Step("Start SDL, init HMI", common.start)
  runner.Step("Register App", common.registerAppWOPTU)
  runner.Step("Activate App", common.activateApp)
  runner.Step("Unprotected RPC in unprotected mode", unprotectedRpcInUnprotectedModeEncryptedRequired)
  runner.Step("Register App_2", common.registerApp, { 2 })
  runner.Step("Policy Table Update", common.policyTableUpdate, { ptUpdate })
  runner.Step("Unprotected RPC in unprotected mode, Encrypted not required",
    common.unprotectedRpcInUnprotectedModeSuccess)

  runner.Title("Test")
  runner.Step("IGNITION OFF", common.ignitionOff)
  runner.Step("IGNITION ON", common.start)
  runner.Step("Register App", common.reRegisterAppSuccess)
  runner.Step("Activate App", common.activateApp)
  runner.Step("Unprotected RPC in unprotected mode, Encrypted not required",
    common.unprotectedRpcInUnprotectedModeSuccess)

  runner.Title("Postconditions")
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL, restore SDL settings", common.postconditions)
end
