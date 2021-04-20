-----------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-----------------------------------------------------------------------------------------------------------------------
-- Description: Opening of the protected Audio/Video/RPC service with successful OnServiceUpdate notification
--
-- Preconditions:
-- 1) SDL certificate is missing/expired
-- 2) App is registered with NAVIGATION appHMIType and activated
-- Steps:
-- 1) App sends StartService request (<service_type>, encryption = true)
-- SDL does:
--   - send OnServiceUpdate (<service_type>, REQUEST_RECEIVED) to HMI
--   - send GetSystemTime() request to HMI and wait for the response
-- 2) HMI sends valid GetSystemTime response
-- SDL does:
--   - start PTU sequence and send OnStatusUpdate(UPDATE_NEEDED) to HMI
-- 3) Policy Table Update is finished successfully and brought valid SDL certificate
-- SDL does:
--   - send OnStatusUpdate(UP_TO_DATE) to HMI
--   - starts TLS handshake
-- 4) App provides valid mobile certificate during TLS handshake
-- SDL does:
--   - finish TLS handshake successfully
--   - send OnServiceUpdate (<service_type>, REQUEST_ACCEPTED) to HMI
--   - send StartServiceACK(<service_type>, encryption = true) to App
--   - leave the app in current HMI level
-----------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Constants ]]
local serviceId = 11

--[[ Local Functions ]]
function common.onServiceUpdateFunc(pServiceTypeValue)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceTypeValue, appID = common.getHMIAppId() },
    { serviceEvent = "REQUEST_ACCEPTED", serviceType = pServiceTypeValue, appID = common.getHMIAppId() })
  :Times(2)

  common.getHMIConnection():ExpectRequest("BasicCommunication.CloseApplication")
  :Times(0)

  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

function common.serviceResponseFunc(pServiceId)
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.const.FRAME_INFO.START_SERVICE_ACK,
    encryption = true
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates,
  { "./files/Security/client_credential_expired.pem", true })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Start Video Service protected, ACCEPTED", common.startServiceWithOnServiceUpdate, { serviceId, 1, 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
