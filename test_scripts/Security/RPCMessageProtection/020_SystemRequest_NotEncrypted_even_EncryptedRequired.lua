---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md
-- Description:
-- Precondition:
-- 1) App registered and activated, OnHMIStatus(FULL)
-- 2) RPC needs protection, encryption_required parameters to App within app_policies = true and to the
--    appropriate function_group (Base-4) = true
-- In case:
-- 1) Mobile app sends specific RPC to SDL (see list below)
-- SDL does:
-- 1) proceed with this RPC and respond to mobile app (non-encrypted)
-- In case:
-- 1) RPC service 7 is started in protected mode
-- 2) Mobile app sends specific RPC to SDL (see list below)
-- SDL does:
-- 1) proceed with this RPC and respond to mobile app (encrypted)
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

--[[ Local Variables ]]
local file = "./files/action.png"
local param = {
  requestType = "PROPRIETARY",
  fileName = "action.png"
}

--[[ Local Functions ]]
local function rpcUnencryptedEncryptionNotRequired()
  local cid = common.getMobileSession():SendRPC("SystemRequest", param, file)
  common.getHMIConnection():ExpectRequest("BasicCommunication.SystemRequest")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

local function rpcUnencryptedEncryptionRequired()
	local cid = common.getMobileSession():SendRPC("SystemRequest", param, file)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "ENCRYPTION_NEEDED" })
end

local function rpcEncryptedEncryptionRequired()
  local cid = common.getMobileSession():SendEncryptedRPC("SystemRequest", param, file)
  common.getHMIConnection():ExpectRequest("BasicCommunication.SystemRequest")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
    end)
  common.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Preloaded update", common.updatePreloadedPT, { true, true })
runner.Step("Start SDL, init HMI", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Non-encrypted SystemRequest, unprotected RPC, encrypted required",
  rpcUnencryptedEncryptionNotRequired)
runner.Step("Start RPC Service protected", common.switchRPCServiceToProtected)
runner.Step("Non-encrypted SystemRequest, protected RPC, encrypted required",
  rpcUnencryptedEncryptionRequired)
runner.Step("Protected SystemRequest, protected RPC, encrypted required",
  rpcEncryptedEncryptionRequired)

runner.Title("Postconditions")
runner.Step("Clean sessions", common.cleanSessions)
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
