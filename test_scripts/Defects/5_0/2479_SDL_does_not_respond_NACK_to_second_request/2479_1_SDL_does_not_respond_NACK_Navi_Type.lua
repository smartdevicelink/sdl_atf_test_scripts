---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2379
--
-- Description:
-- SDL does not respond NACK to second request
-- Steps to reproduce:
-- 1) In case mobile side send two start VIDEO secure service requests
-- Expected:
-- 1) Respond NACK to second request keep active VIDEO service that was already started
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Security/DTLS/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local function ]]
function startServiceProtectedSecond(pServiceId)
  common.getMobileSession():StartSecureService(pServiceId)
  common.getMobileSession():ExpectHandshakeMessage()
  :Times(0)
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_NACK,
    encryption = false
  })
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
runner.Step("Start RPC Service protected", common.startServiceProtected, { 11 })
runner.Step("Start seconde RPC Service protected", startServiceProtectedSecond, { 11 })

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings", common.postconditions)
