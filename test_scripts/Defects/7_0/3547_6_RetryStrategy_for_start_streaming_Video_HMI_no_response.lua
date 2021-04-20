---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3547
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. Navigation app is registered
-- 2. App try to start Video service
-- SDL does
--  - send `Navi.StartStream` requests to HMI
-- 3. HMI responds with 'REJECTED'
-- SDL does:
--  - re-sends `Navi.StartStream` requests to HMI a few times
--    (equal to `StartStreamRetry` .ini parameter)
-- 4. HMI doesn't responds to any request
-- SDL does:
--  - not send new `Navi.StartStream` requests to HMI
--  - unregister App once timeout for last request is expired
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_0/common_3547')

--[[ Local Variables ]]
local expNumOfAttempts = 3

--[[ Local Functions ]]
local function startAudioVideoService(pServiceId)
  common.mobile.getSession():StartService(pServiceId)
  common.hmi.getConnection():ExpectRequest(common.requestNames[pServiceId].start)
  :Do(function()
      -- common.sendErrorResponse(data, 500) -- no response from HMI
    end)
  :Times(expNumOfAttempts + 1)
  common.mobile.getSession():ExpectEndService(pServiceId)
  common.hmi.getConnection():ExpectRequest(common.requestNames[pServiceId].stop)
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  common.mobile.getSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "PROTOCOL_VIOLATION" })
  common.run.wait(4000)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("SetNewRetryValue", common.setSDLIniParameter, { "StartStreamRetry", expNumOfAttempts .. ", 1000" })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI, PTU", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Retry sequence start VIDEO streaming", startAudioVideoService, { 11 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

