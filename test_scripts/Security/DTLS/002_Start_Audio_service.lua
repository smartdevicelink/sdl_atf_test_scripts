---------------------------------------------------------------------------------------------------
-- In case:
-- 1) SDL is configured with parameter ‘Protocol = DTLSv1.0’
-- 2) SDL has up-to-date certificates in Policy Table
-- 3) And app is configured to use DTLS protocol for communication with SDL
-- 4) And this app is registered and RPC service is started in unprotected mode
-- 5) And this app is try to start Audio/Video service in protected mode
-- SDL does:
-- 1) Perform protected service handshake
-- 2) Reply with StartServiceACK encryption = true
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
runner.Step("Start Audio Service protected", common.startServiceProtected, { 10 })

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
