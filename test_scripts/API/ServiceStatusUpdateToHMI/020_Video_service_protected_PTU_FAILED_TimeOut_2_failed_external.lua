-----------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-----------------------------------------------------------------------------------------------------------------------
-- Description: Attempt to open protected Audio/Video service with OnServiceUpdate notification
-- and unsuccessful PTU due to timeout
--
-- Script's purposes:
--   1) check retry sequence
--   2) check SDL's try counter is reset during consecutive scenarios:
--     - failed PTU retry sequence
--     - failed PTU retry sequence
--
-- Note: script is applicable for EXTERNAL_PROPRIETARY SDL policy mode only
-----------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

--[[ Local Constants ]]
local serviceId = 11
local numOfIter = 2
local secondsBetweenRetries = { 1, 2 }

--[[ Local Variables ]]
local timeout = 10000 * numOfIter + 10000
local result = { }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  local retries = {}
  for i = 1, numOfIter do
    table.insert(retries, secondsBetweenRetries[i])
  end
  pTbl.policy_table.module_config.timeout_after_x_seconds = 5
  pTbl.policy_table.module_config.seconds_between_retries = retries
end

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

local function startServiceWithOnServiceUpdate_PTU_FAILED(pServiceId, pHandShakeExpeTimes, pGSTExpTimes, pPTUNum)
  result.serviceNackTime = 0
  result.retryFinishedTime = 0
  result.onServiceUpdateTime = 0
  local curRetry = 0
  local function getExpOnStatusUpdate()
    local expRes = {}
    for i = 1, numOfIter + 1 do
      if pPTUNum == 1 or i > 1 then table.insert(expRes, { status = "UPDATE_NEEDED" }) end
      table.insert(expRes, { status = "UPDATING" })
    end
    table.insert(expRes, { status = "UPDATE_NEEDED" })
    return expRes
  end
  local function sendBCOnSystemRequest()
    curRetry = curRetry + 1
    local delay = 0
    if curRetry > 1 then
      delay = secondsBetweenRetries[curRetry - 1] * 1000
    end
    common.log("Delay:", delay)
    RUN_AFTER(function()
      common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = "files/ptu.json" })
      common.log("HMI->SDL:", "BC.OnSystemRequest")
    end, delay)
  end
  function common.policyTableUpdateFunc()
    function common.policyTableUpdate()
      local cid = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",
        { policyType = "module_config", property = "endpoints" })
      common.getHMIConnection():ExpectResponse(cid)
      common.getHMIConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
      :Do(function()
          common.log("SDL->HMI:", "BC.PolicyUpdate")
          sendBCOnSystemRequest()
        end)
      common.getMobileSession():ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, d)
          common.log("SDL->MOB:", "OnSystemRequest", d.payload.requestType)
        end)
      :Times(numOfIter + 1)
      :Timeout(timeout)
    end
    local expNotifRes = getExpOnStatusUpdate()
    common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", table.unpack(expNotifRes))
    :Times(#expNotifRes)
    :Do(function(e, d)
        common.log("SDL->HMI:", d.method, d.params.status)
        if e.occurences == #expNotifRes then
          result.retryFinishedTime = timestamp()
        end
        if e.occurences > 1 and e.occurences < #expNotifRes and d.params.status == "UPDATE_NEEDED" then
          sendBCOnSystemRequest()
        end
      end)
    :Timeout(timeout)
    common.policyTableUpdate()
    common.wait(timeout)
    end
  common.startServiceWithOnServiceUpdate(pServiceId, pHandShakeExpeTimes, pGSTExpTimes)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, {
  common.serviceData[10].forceCode .. ', ' .. common.serviceData[11].forceCode })
runner.Step("Init SDL certificates", common.initSDLCertificates,
  { "./files/Security/client_credential_expired.pem", false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate, { ptUpdate })
runner.Step("App activation", common.activateApp)

runner.Title("Test")

runner.Title("PTU 1")
runner.Step("Start " .. common.serviceData[serviceId].serviceType .. " service protected, REJECTED",
  startServiceWithOnServiceUpdate_PTU_FAILED, { serviceId, 0, 1, 1 })
runner.Step("Check result", common.checkResult, { result })

runner.Step("App activation", common.activateApp)

runner.Title("PTU 2")
runner.Step("Start " .. common.serviceData[serviceId].serviceType .. " service protected, REJECTED",
  startServiceWithOnServiceUpdate_PTU_FAILED, { serviceId, 0, 1, 2 })
runner.Step("Check result", common.checkResult, { result })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
