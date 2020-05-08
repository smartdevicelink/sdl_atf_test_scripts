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
-- SDL does:
-- 1) resend this notification to mobile application (non-encrypted)
-- In case:
-- 1) RPC service 7 is started in protected mode
-- 2) HMI sends specific notification to SDL (see list below)
-- SDL does:
-- 1) resend this notification to mobile application (encrypted)
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
local function rpcUnencryptedEncryptionNotRequired()
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "HTTP", fileName = "files/icon_png.png" })
  common.getMobileSession():ExpectNotification("OnSystemRequest", { requestType = "HTTP" })
end

local function rpcEncryptedEncryptionRequired()
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "HTTP", fileName = "files/icon_png.png" })
  common.getMobileSession():ExpectEncryptedNotification("OnSystemRequest", { requestType = "HTTP" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update", common.updatePreloadedPT, { true, true })
runner.Step("Start SDL, init HMI", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Non-encrypted OnSystemRequest, unprotected RPC, encrypted required",
  rpcUnencryptedEncryptionNotRequired)
runner.Step("Start RPC Service protected", common.switchRPCServiceToProtected)
runner.Step("Encrypted OnSystemRequest, protected RPC, encrypted required",
  rpcEncryptedEncryptionRequired)

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
