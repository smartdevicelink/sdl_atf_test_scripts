---------------------------------------------------------------------------------------------------
-- TBA
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/4_5/Trigger_PTU_NO_Certificate/common')
local commonDTLS = require('test_scripts/DTLS/common')
local runner = require('user_modules/script_runner')
-- add unsupported SDL protocol version
local constants = require('protocol_handler/ford_protocol_constants')
constants.FRAME_SIZE["P9"] = 131084

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set DTLS protocol in SDL", commonDTLS.setSDLConfigParameter, { "Protocol", "DTLSv1.0" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update Certificate", common.policyTableUpdate, { commonDTLS.ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

runner.Step("Switch RPC service to Protected mode", commonDTLS.startServiceProtected, { 7 })

runner.Step("PutFile. Session Secure. Sent data Protected. 1st frame UNprotected", commonDTLS.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = true, isFirstFrameEncrypted = false }
})

runner.Step("PutFile. Session Secure. Sent data Protected. 1st frame Protected", commonDTLS.putFileByFrames, {
  { isSessionEncrypted = true, isSentDataEncrypted = true, isFirstFrameEncrypted = true }
})

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", commonDTLS.postconditions)
