---------------------------------------------------------------------------------------------------
-- In case:
-- 1) SDL is configured with parameter ‘Protocol = DTLSv1.0’
-- 2) And app is configured to use DTLS protocol for communication with SDL
-- 3) And this app is registered and RPC service is started in protected mode
-- 4) And this app tries to send multi-packet RPC (e.g. PutFile)
-- 5) And 1st frame is non-encrypted (or encrypted) and other frames are encrypted
-- SDL does:
-- 1) Process this RPC successfully in protected mode
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Security/DTLS/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set DTLS protocol in SDL", common.setSDLIniParameter, { "Protocol", "DTLSv1.0" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Switch RPC service to Protected mode", common.startServiceProtected, { 7 })
runner.Step("PutFile. Session Secure. Sent data Protected. 1st frame UNprotected", common.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = true, isFirstFrameEncrypted = false }
})
runner.Step("PutFile. Session Secure. Sent data Protected. 1st frame Protected", common.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = true, isFirstFrameEncrypted = true }
})

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
