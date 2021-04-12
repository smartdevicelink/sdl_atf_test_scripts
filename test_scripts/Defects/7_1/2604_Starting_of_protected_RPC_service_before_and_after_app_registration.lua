---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2604
---------------------------------------------------------------------------------------------------
-- Description: Check SDL rejects starting of protected RPC service before app registration
-- and accepts it after (when app id became available)
--
-- Steps:
-- 1. App starts unprotected RPC service
-- 2. App tries to switch RPC service to protected mode
-- SDL does:
--  - respond with StartServiceNACK to App
--  - send 'BC.OnServiceUpdate' (REQUEST_REJECTED/INVALID_CERT) to HMI
-- 3. App is registered
-- 4. App tries to switch RPC service to protected mode
-- SDL does:
--  - respond with StartServiceACK to App
--  - send 'BC.OnServiceUpdate' (REQUEST_ACCEPTED) to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Security/SSLHandshakeFlow/common")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
  local serviceId = 7

--[[ Local Functions ]]
local function startServiceUnprotectedACK()
  common.getMobileSession():StartService(serviceId)
  common.getHMIConnection():ExpectRequest("BasicCommunication.OnServiceUpdate",
    { serviceType = "RPC", serviceEvent = "REQUEST_RECEIVED" },
    { serviceType = "RPC", serviceEvent = "REQUEST_ACCEPTED" })
  :Times(2)
end

local function startServiceProtectedNACK()
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = common.frameInfo.START_SERVICE_NACK,
    encryption = false
  })
  common.getMobileSession():ExpectHandshakeMessage()
  common.getHMIConnection():ExpectRequest("BasicCommunication.OnServiceUpdate",
    { serviceType = "RPC", serviceEvent = "REQUEST_RECEIVED" },
    { serviceType = "RPC", serviceEvent = "REQUEST_REJECTED", reason = "INVALID_CERT" })
  :Times(2)
end

local function startServiceProtectedACK()
  common.getMobileSession():StartSecureService(serviceId)
  common.getMobileSession():ExpectControlMessage(serviceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
  common.getMobileSession():ExpectHandshakeMessage()
  common.getHMIConnection():ExpectRequest("BasicCommunication.OnServiceUpdate",
    { serviceType = "RPC", serviceEvent = "REQUEST_RECEIVED" },
    { serviceType = "RPC", serviceEvent = "REQUEST_ACCEPTED" })
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App starts RPC Service in Unprotected mode ACK", startServiceUnprotectedACK)
runner.Step("App tries to switch RPC Service to Protected mode NACK", startServiceProtectedNACK)
runner.Step("Register App", common.registerApp)
runner.Step("App tries to switch RPC Service to Protected mode ACK", startServiceProtectedACK)
runner.Step("Activate App", common.activateAppProtected)
runner.Step("App sends AddCommand in Protected mode", common.sendAddCommandProtected)

runner.Title("Postconditions")
runner.Step("Stop SDL, clean-up certificates", common.postconditions)
