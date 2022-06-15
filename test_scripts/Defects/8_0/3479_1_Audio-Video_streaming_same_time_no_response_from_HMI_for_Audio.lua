---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3479
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL continue Video streaming in case:
--  - both Audio/Video streaming started at the same time
--  - HMI doesn't respond to Navigation.StartAudioStream requests
--
-- In case:
-- 1. App starts Video and Audio streaming at the same time
-- 2. SDL sends requests to HMI:
--   a) Navigation.StartStream
--   b) Navigation.StartAudioStream
-- 3. HMI responds to a) and doesn't respond to b)
-- 4. SDL sends 3 more b) requests
-- 5. HMI still doesn't respond
-- SDL does:
--  - stop Audio service
--  - not stop Video service
--  - continue Video streaming from App
--  - not unregister App with PROTOCOL_VIOLATION reason
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/8_0/common_3479_2810')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local delay = 500 --ms
local numOfIterations = 2

--[[ Local Functions ]]
local function appStartStreaming(pSendEndServiceAck)
  common.run.wait(10000)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate")
  :Do(function(_, data) common.log(common.ld[2], "BC.OnServiceUpdate", data.params.serviceType, data.params.serviceEvent) end)
  :Times(4)

  common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered")
  :Do(function() common.log("OnAppInterfaceUnregistered") end)
  :Times(0)
  common.getHMIConnection():ExpectNotification("BC.CloseApplication")
  :Do(function() common.log("BC.CloseApplication") end)
  :Times(0)

  common.getMobileSession():ExpectEndService(common.services.video)
  :Times(0)

  common.startStreamingNoAnswer(common.services.audio, 0, delay, pSendEndServiceAck)
  common.startStreaming(common.services.video, 0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for i = 1, numOfIterations do
  runner.Title("Iteration " .. i .. " with EndServiceAck")
  runner.Step("App starts A/V streaming", appStartStreaming, { true })
  runner.Step("App stops A/V streaming", common.stopStreaming, { common.services.video })
end
for i = 1, numOfIterations do
  runner.Title("Iteration " .. i .. " without EndServiceAck")
  runner.Step("App starts A/V streaming", appStartStreaming, { false })
  runner.Step("App stops A/V streaming", common.stopStreaming, { common.services.video })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
