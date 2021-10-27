---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3547, 3479
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
-- 4. HMI responds with 'REJECTED' to all requests
-- SDL does:
--  - not send new `Navi.StartStream` requests to HMI
--  - send EndService request to the App
--  - not unregister App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_0/common_3547')

--[[ Local Variables ]]
local expNumOfAttempts = 3

--[[ Local Functions ]]
local function startAudioVideoService(pServiceId)
  common.hmi.getConnection():ExpectRequest(common.requestNames[pServiceId].start)
  :Do(function(_, data)
      common.sendErrorResponse(data, 500)
    end)
  :Times(expNumOfAttempts + 1)
  common.mobile.getSession():StartService(pServiceId)
  common.mobile.getSession():ExpectEndService(pServiceId)
  common.hmi.getConnection():ExpectRequest(common.requestNames[pServiceId].stop)
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppUnregistered"):Times(0)
  common.mobile.getSession():ExpectNotification("OnAppInterfaceUnregistered"):Times(0)
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

