-----------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-----------------------------------------------------------------------------------------------------------------------
-- Description: Attempt to open unprotected Video/Audio service with OnServiceUpdate notification in case
-- App start stream in NONE HMI level
--
-- Preconditions:
-- 1) SDL certificate is missing/expired
-- 2) Force protection for the service is switched OFF
-- 3) App is registered with NAVIGATION appHMIType
-- Steps:
-- 1) App sends StartService request (<service_type>, encryption = false)
-- SDL does:
--   - send OnServiceUpdate (<service_type>, REQUEST_RECEIVED) to HMI
--   - send OnServiceUpdate (<service_type>, REQUEST_REJECTED) to HMI
--   - send StartServiceNACK(<service_type>, encryption = false) to App
-----------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Constants ]]
local serviceId = 11

--[[ Local Functions ]]
function common.startServiceFunc(pServiceId)
  local msg = {
    frameType = common.const.FRAME_TYPE.CONTROL_FRAME,
    serviceType = pServiceId,
    frameInfo = common.const.FRAME_INFO.START_SERVICE,
    encryption = false
  }
  common.getMobileSession():Send(msg)
end

function common.onServiceUpdateFunc(pServiceTypeValue)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceTypeValue, appID = common.getHMIAppId() },
    { serviceEvent = "REQUEST_REJECTED", serviceType = pServiceTypeValue, appID = common.getHMIAppId() })
  :Times(2)
end

function common.serviceResponseFunc(pServiceId)
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.const.FRAME_INFO.START_SERVICE_NACK,
    encryption = false
  })
end

function common.policyTableUpdateFunc()
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)

runner.Title("Test")
runner.Step("Start Video Service unprotected, App in NONE level",
  common.startServiceWithOnServiceUpdate, { serviceId, 0, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
