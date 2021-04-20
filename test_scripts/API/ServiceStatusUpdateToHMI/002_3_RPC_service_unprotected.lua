-----------------------------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-----------------------------------------------------------------------------------------------------------------------
-- Description: Opening of the non-protected Audio/Video/RPC service with successful OnServiceUpdate notification
--
-- Preconditions:
-- 1) SDL certificate is missing/expired
-- 2) App is registered with NAVIGATION appHMIType and activated
-- Steps:
-- 1) App sends StartService request (<service_type>, encryption = false)
-- SDL does:
--   - send OnServiceUpdate (<service_type>, REQUEST_RECEIVED) to HMI
--   - not send GetSystemTime() request to HMI
--   - not start PTU sequence
--   - send OnServiceUpdate (<service_type>, REQUEST_ACCEPTED) to HMI
--   - send StartServiceACK(<service_type>, encryption = false) to App
--   - leave the app in current HMI level
-----------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Constants ]]
local serviceId = 7

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

function common.serviceResponseFunc(pServiceId)
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.const.FRAME_INFO.START_SERVICE_ACK,
    encryption = false
  })
end

function common.policyTableUpdateFunc()
  -- common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate")
  -- :Times(0) -- There is an issue: SDL sends 'UPDATE_NEEDED' if it was build in EXTERNAL_PROPRIETARY mode
  -- https://github.com/smartdevicelink/sdl_core/issues/2995
end

function common.onServiceUpdateFunc(pServiceTypeValue)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceTypeValue },
    { serviceEvent = "REQUEST_ACCEPTED", serviceType = pServiceTypeValue })
  :Times(2)
  :ValidIf(function(_, data)
    if data.params.appID then
      return false, "OnServiceUpdate notification contains unexpected appID"
    end
    return true
  end)

  common.getHMIConnection():ExpectRequest("BasicCommunication.CloseApplication")
  :Times(0)

  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Start RPC Service unprotected, ACCEPTED", common.startServiceWithOnServiceUpdate, { serviceId, 0, 0 } )

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
