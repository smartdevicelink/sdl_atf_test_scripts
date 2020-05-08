---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md
-- Description:
-- Precondition:
-- 1) App registered and activated, OnHMIStatus(FULL)
-- 2) RPC service 7 is started in protected mode
-- 3) RPC doesn't need protection, encryption_required parameters to App within app_policies = true and to the
--    appropriate function_group (Base-4) = false
-- In case:
-- 1) The mobile application sends unencrypted RPC request (AddCommand) to SDL
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
  [001] = { a = true, f = false },
  [002] = { a = true, f = nil },
  [003] = { a = false, f = true },
  [004] = { a = false, f = false },
  [005] = { a = false, f = nil },
  [006] = { a = nil, f = false },
  [007] = { a = nil, f = nil }
}

--[[ Local Functions ]]
local function unprotectedRpcInProtectedModeEncryptedNotRequired()
  local cid = common.getMobileSession():SendRPC("AddCommand", common.getAddCommandParams(1))
  common.getHMIConnection():ExpectRequest("UI.AddCommand", common.getAddCommandParams(1))
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHashChange")
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

  runner.Title("Test")
  runner.Step("Start RPC Service protected", common.switchRPCServiceToProtected)
  runner.Step("Unprotected RPC in protected mode, param for App="..tostring(tc.a)..",for Group="..tostring(tc.f),
    unprotectedRpcInProtectedModeEncryptedNotRequired)

  runner.Title("Postconditions")
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL, restore SDL settings", common.postconditions)
end
