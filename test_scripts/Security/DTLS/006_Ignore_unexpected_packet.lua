---------------------------------------------------------------------------------------------------
-- In case:
-- 1) SDL is configured with parameter ‘Protocol = DTLSv1.0’
-- 2) And app is configured to use DTLS protocol for communication with SDL
-- 3) And this app is registered and RPC service is started in protected mode
-- 4) And this app tries to send multi-packet RPC (e.g. PutFile)
-- 5) And while sending at least one of the encrypted packet is malformed (or unexpected)
-- SDL does:
-- 1) Ignore malformed (or unexpected) packet
-- 2) Process this RPC successfully in protected mode
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
runner.Step("PutFile. Session Insecure. Sent data UNprotected", common.putFileByFrames, {
  { isSessionEncrypted = false, isSentDataEncrypted = false }
})
runner.Step("PutFile. Session Insecure. Sent data UNprotected + Unexpected frame", common.putFileByFrames, {
  { isSessionEncrypted = false, isSentDataEncrypted = false, isUnexpectedFrameInserted = true }
})
runner.Step("Switch RPC service to Protected mode", common.startServiceProtected, { 7 })
runner.Step("PutFile. Session Secure. Sent data UNprotected", common.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = false }
})
runner.Step("PutFile. Session Secure. Sent data UNprotected + Unexpected frame", common.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = false, isUnexpectedFrameInserted = true }
})
runner.Step("PutFile. Session Secure. Sent data Protected", common.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = true }
})
runner.Step("PutFile. Session Secure. Sent data Protected + Unexpected frame", common.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = true, isUnexpectedFrameInserted = true }
})

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
