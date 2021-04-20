-----------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-----------------------------------------------------------------------------------------------------------------------
-- Description: Attempt to open protected Audio/Video service with OnServiceUpdate notification
-- in case of non force protection and invalid SDL certificate
--
-- Preconditions:
-- 1) SDL certificate is missing/expired
-- 2) Force protection for the service is switched OFF
-- 3) App is registered with NAVIGATION appHMIType and activated
-- Steps:
-- 1) App sends StartService request (<service_type>, encryption = true)
-- SDL does:
--   - send OnServiceUpdate (<service_type>, REQUEST_RECEIVED) to HMI
--   - send GetSystemTime() request to HMI and wait for the response
-- 2) HMI sends valid GetSystemTime response
-- SDL does:
--   - start PTU sequence and send OnStatusUpdate(UPDATE_NEEDED) to HMI
-- 3) Policy Table Update is finished successfully and brought invalid SDL certificate
-- SDL does:
--   - send OnStatusUpdate(UP_TO_DATE) to HMI
--   - send OnServiceUpdate (<service_type>, REQUEST_ACCEPTED, PROTECTION_DISABLED) to HMI
--   - send StartServiceACK(<service_type>, encryption = false) to App
--   - leave the app in current HMI level
-----------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Constants ]]
local videoServiceId = 11
local audioServiceId = 10

--[[ Local Functions ]]
function common.ptUpdate(pTbl)
  local filePath = "./files/Security/client_credential_expired.pem"
  local crt = common.readFile(filePath)
  pTbl.policy_table.module_config.certificate = crt
end

function common.onServiceUpdateFunc(pServiceTypeValue)
 common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
   { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceTypeValue, appID = common.getHMIAppId() },
   { serviceEvent = "REQUEST_ACCEPTED", serviceType = pServiceTypeValue, appID = common.getHMIAppId(),
     reason = "PROTECTION_DISABLED" })
   :Times(2)

  common.getHMIConnection():ExpectRequest("BasicCommunication.CloseApplication")
  :Times(0)

  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

function common.serviceResponseFunc(pServiceId)
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = false
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
runner.Step("Start Video Service protected, ACCEPTED", common.startServiceWithOnServiceUpdate, { videoServiceId, 0, 1 })
runner.Step("Start Audio Service protected, ACCEPTED", common.startServiceWithOnServiceUpdate, { audioServiceId, 0, 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
