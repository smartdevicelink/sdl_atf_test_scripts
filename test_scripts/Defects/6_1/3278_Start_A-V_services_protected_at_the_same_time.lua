---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3278
--
-- Steps:
-- 1. Set up all required certificates to for protected mode
-- 2. Start SDL, HMI, connect Mobile device
-- 3. Register NAVIGATION application
-- 4. Activate application
-- 5. Start Audio service in protected mode
-- SDL does:
--   - start SSL handshake procedure
-- 6. Start Video service in protected mode while handshake is in progress
-- SDL does:
--   - finish SSL handshake successfully
--   - start Audio/Video services in protected mode
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Security/SSLHandshakeFlow/common")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

local function startServiceProtectedACK(pServiceId)
  local serviceId = pServiceId
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
end

local function startServicesProtected()
  startServiceProtectedACK(10)
  RUN_AFTER(function() startServiceProtectedACK(11) end, 25)
  common.getMobileSession():ExpectHandshakeMessage()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App", common.registerApp)
runner.Step("Register App", common.activateApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("Start A/V services simultaneously", startServicesProtected)

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
