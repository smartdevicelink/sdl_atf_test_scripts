---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md
-- Description:
-- Precondition:
-- 1) App registered and activated, OnHMIStatus(FULL)
-- 2) RPC needs protection, encryption_required parameters to App within app_policies = true and to the
--    appropriate function_group (Base-4) = true
-- In case:
-- 1) HMI sends specific notification to SDL (see list below)
-- 2) Or Mobile app sends specific RPC to SDL (see list below)
-- SDL does:
-- 1) resend this notification to mobile application (non-encrypted)
-- 2) proceed with this RPC and respond to mobile app (non-encrypted)
--
-- Excluded from force protection RPCs and Notifications:
--   - RegisterAppInterface, SystemRequest, PutFile
--   - OnPermissionsChange, OnSystemRequest
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Security/RPCMessageProtection/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function registerApp()
  common.getMobileSession():StartService(7)
  :Do(function()
      local cid = common.getMobileSession():SendRPC("RegisterAppInterface", common.getConfigAppParams())
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
      common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession():ExpectNotification("OnPermissionsChange")
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update", common.updatePreloadedPT, { true, true })
runner.Step("Start SDL, init HMI", common.start)

runner.Title("Test")
runner.Step("Non-encrypted RegAppInterface, OnPermChange, unprotected RPC, encrypted required", registerApp)

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
