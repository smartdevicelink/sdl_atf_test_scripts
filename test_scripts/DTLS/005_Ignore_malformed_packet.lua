---------------------------------------------------------------------------------------------------
-- TBA
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/DTLS/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set DTLS protocol in SDL", common.setSDLConfigParameter, { "Protocol", "DTLSv1.0" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

runner.Step("PutFile. Session Insecure. Sent data UNprotected", common.putFileByFrames, {
  { isSessionEncrypted = false, isSentDataEncrypted = false }
})

runner.Step("PutFile. Session Insecure. Sent data UNprotected + Malformed frame", common.putFileByFrames, {
  { isSessionEncrypted = false, isSentDataEncrypted = false, isMalformedFrameInserted = true }
})

runner.Step("Switch RPC service to Protected mode", common.startServiceProtected, { 7 })

runner.Step("PutFile. Session Secure. Sent data UNprotected", common.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = false }
})

runner.Step("PutFile. Session Secure. Sent data UNprotected + Malformed frame", common.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = false, isMalformedFrameInserted = true }
})

runner.Step("PutFile. Session Secure. Sent data Protected", common.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = true }
})

runner.Step("PutFile. Session Secure. Sent data Protected + Malformed frame", common.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = true, isMalformedFrameInserted = true }
})

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
