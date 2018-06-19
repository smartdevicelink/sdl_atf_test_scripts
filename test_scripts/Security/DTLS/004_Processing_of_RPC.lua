---------------------------------------------------------------------------------------------------
-- In case:
-- 1) SDL is configured with parameter ‘Protocol = DTLSv1.0’
-- 2) And app is configured to use DTLS protocol for communication with SDL
-- 3) And this app is registered and RPC service is started in protected mode
-- 4) And app tries to send any RPC
-- SDL does:
-- 1) Process this RPC successfully in protected mode
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Security/DTLS/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function rpcInProtectedModeSuccess()
	local params = {
    cmdID = 1,
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local cid = common.getMobileSession():SendEncryptedRPC("AddCommand", params)
  common.getHMIConnection():ExpectRequest("UI.AddCommand", params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():ExpectEncryptedResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectEncryptedNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set DTLS protocol in SDL", common.setSDLIniParameter, { "Protocol", "DTLSv1.0" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Start RPC Service protected", common.startServiceProtected, { 7 })
runner.Step("Process RPC in protected mode", rpcInProtectedModeSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
