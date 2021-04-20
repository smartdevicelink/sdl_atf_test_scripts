-----------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-----------------------------------------------------------------------------------------------------------------------
-- Description: Attempt to open protected Audio/Video service with OnServiceUpdate notification
-- and unsuccessful PTU due to timeout
-- Note: script is applicable for PROPRIETARY SDL policy mode only
--
-- Preconditions:
-- 1) SDL certificate is missing/expired
-- 2) Force protection for the service is switched ON
-- 3) App is registered with NAVIGATION appHMIType and activated
-- Steps:
-- 1) App sends StartService request (<service_type>, encryption = true)
-- SDL does:
--   - send OnServiceUpdate (<service_type>, REQUEST_RECEIVED) to HMI
--   - send GetSystemTime() request to HMI and wait for the response
-- 2) HMI sends valid GetSystemTime response
-- SDL does:
--   - start PTU sequence and send OnStatusUpdate(UPDATE_NEEDED) to HMI
-- 3) Policy Table Update retry sequence is finished without update from App
-- SDL does:
--   - send OnStatusUpdate(UPDATE_NEEDED) to HMI
--   - send OnServiceUpdate (<service_type>, REQUEST_REJECTED, PTU_FAILED) to HMI
--   - send StartServiceNACK(<service_type>, encryption = false) to App
--   - send BC.CloseApplication to HMI
--   - send OnHMIStatus(NONE) to mobile app
-----------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY" } } }

--[[ Local Constants ]]
local serviceId = 11
local numOfIter = 2

--[[ Local Variables ]]
local timeout = 10000 * numOfIter + 10000
local result = {
  serviceNackTime = 0,
  retryFinishedTime = 0,
  onServiceUpdateTime = 0
}

--[[ Local Functions ]]
function common.onServiceUpdateFunc(pServiceTypeValue)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceTypeValue, appID = common.getHMIAppId() },
    { serviceEvent = "REQUEST_REJECTED", serviceType = pServiceTypeValue, appID = common.getHMIAppId(),
      reason = "PTU_FAILED" })
  :Do(function(e, d)
      common.log("SDL->HMI:", "BC.OnServiceUpdate", d.params.serviceEvent, d.params.reason)
      if e.occurences == 2 then
        result.onServiceUpdateTime = timestamp()
      end
    end)
  :Times(2)
  :Timeout(timeout)

  common.getHMIConnection():ExpectRequest("BasicCommunication.CloseApplication", { appID = common.getHMIAppId() })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  :Timeout(timeout)

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  :Timeout(timeout)
end

function common.serviceResponseFunc(pServiceId)
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_NACK,
    encryption = false
  })
  :Do(function(_, data)
      if data.frameInfo == common.frameInfo.START_SERVICE_NACK then
        common.log("SDL->MOB:", "START_SERVICE_NACK")
        result.serviceNackTime = timestamp()
      end
    end)
  :Timeout(timeout)
end

local function ptUpdate(pTbl)
  local retries = {}
  for _ = 1, numOfIter do
    table.insert(retries, 1)
  end
  pTbl.policy_table.module_config.timeout_after_x_seconds = 5
  pTbl.policy_table.module_config.seconds_between_retries = retries
end

function common.policyTableUpdateFunc()
  function common.policyTableUpdate()
    local cid = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
    common.getHMIConnection():ExpectResponse(cid)
    :Do(function()
        common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
          { requestType = "PROPRIETARY", fileName = "files/ptu.json" })
        common.log("HMI->SDL:", "BC.OnSystemRequest")
        common.getMobileSession():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function(_, d)
            common.log("SDL->MOB:", "OnSystemRequest  ", d.payload.requestType)
          end)
        :Times(numOfIter + 1)
        :Timeout(timeout)
      end)
  end
  local expRes = {}
  for _ = 1, numOfIter + 1 do
    table.insert(expRes, { status = "UPDATE_NEEDED" })
    table.insert(expRes, { status = "UPDATING" })
  end
  table.insert(expRes, { status = "UPDATE_NEEDED" })
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", unpack(expRes))
  :Times(#expRes)
  :Do(function(e, d)
      common.log("SDL->HMI:", d.method, d.params.status)
      if e.occurences == #expRes then
        result.retryFinishedTime = timestamp()
      end
    end)
  :Timeout(timeout)
  common.policyTableUpdateUnsuccess()
  common.wait(timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { common.serviceData[serviceId].forceCode })
runner.Step("Init SDL certificates", common.initSDLCertificates,
  { "./files/Security/client_credential_expired.pem", false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate, { ptUpdate })
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Start " .. common.serviceData[serviceId].serviceType .. " service protected, REJECTED",
  common.startServiceWithOnServiceUpdate, { serviceId, 0, 1 })
runner.Step("Check result", common.checkResult, { result })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
