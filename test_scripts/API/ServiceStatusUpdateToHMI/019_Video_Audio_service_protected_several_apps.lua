-----------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-----------------------------------------------------------------------------------------------------------------------
-- Description: Opening of the protected Audio/Video service with successful OnServiceUpdate notification
-- in case of 2 applications
--
-- Preconditions:
-- 1) SDL certificate is missing/expired
-- 2) App_1 is registered with NAVIGATION appHMIType
-- 3) App_2 is registered with NAVIGATION appHMIType
-- Steps:
-- 1) App_1 is activated and sends StartService request for the service (<service_type>, encryption = true)
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
-- 4) App_1 provides valid mobile certificate during TLS handshake
-- SDL does:
--   - finish TLS handshake successfully
--   - send OnServiceUpdate (<service_type>, REQUEST_ACCEPTED) to HMI
--   - send StartServiceACK(<service_type>, encryption = true) to App_1
-- 5) App_1 sends StartService request for another service (e.g. Audio)
-- SDL does:
--   - send OnServiceUpdate (<service_type>, REQUEST_RECEIVED) to HMI
--   - send OnServiceUpdate (<service_type>, REQUEST_ACCEPTED) to HMI
--   - send StartServiceACK(<service_type>, encryption = true) to App_1
--   - leave the app in current HMI level
-- 6) App_2 does steps 1) - 5) with the same messages and results
-----------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local crts = {
  [1] = "./files/Security/spt_credential.pem",
  [2] = "./files/Security/spt_credential_2.pem"
}
local videoServiceId = 11
local audioServiceId = 10

--[[ Local Functions ]]
function common.onServiceUpdateFunc(pServiceTypeValue, pAppId)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceTypeValue, appID = common.getHMIAppId(pAppId) },
    { serviceEvent = "REQUEST_ACCEPTED", serviceType = pServiceTypeValue, appID = common.getHMIAppId(pAppId) })
  :Times(2)

  common.getHMIConnection():ExpectRequest("BasicCommunication.CloseApplication")
  :Times(0)

  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
  :Times(0)
end

function common.serviceResponseFunc(pServiceId, pAppId)
  common.getMobileSession(pAppId):ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = true
  })
end

function common.policyTableUpdateFunc()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates,
  { "./files/Security/client_credential.pem", true })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

for i = 1, 2 do
  runner.Step("Set mobile certificate for app " .. i, common.setMobileCrt, { crts[i] })
  runner.Step("App " .. i .. " registration", common.registerApp, { i })
  runner.Step("PolicyTableUpdate", common.policyTableUpdate)
end

runner.Title("Test")
for i = 1, 2 do
  runner.Step("App " .. i .. " activation", common.activateApp, { i })
  runner.Step("Start Video Service app " .. i .. ", ACCEPTED",
    common.startServiceWithOnServiceUpdate, { videoServiceId, 1, 1, i })
  runner.Step("Start Audio Service app " .. i .. ", ACCEPTED",
    common.startServiceWithOnServiceUpdate, { audioServiceId, 0, 0, i })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
