---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2810
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL sends required messages for a streaming stop during unexpected app unregistration
--
-- Steps:
-- 1. Core and HMI are started
-- 2. Mobile app is registered and activated
-- 3. Mobile app starts video and audio services and streamings
-- 4. Connection is closed
-- SDL does:
-- 1. send Navigation.OnVideoDataStreaming(available=false) and Navigation.StopStream to HMI to stop video streaming
-- 2. send Navigation.OnAudioDataStreaming(available=false) and Navigation.StopAudioStream to HMI
--  to stop audio streaming
-- 3. send BasicCommunication.OnAppUnregistered to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/8_0/common_3479_2810')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local videoService = common.services.video
local audioService = common.services.audio

--[[ Local Functions ]]
local function appStartStreaming()
  common.run.wait(5000)
  common.startStreaming(videoService)
  common.startStreaming(audioService)
end

local function unexpectedDisconnect()
  common.disconnect()
  common.getHMIConnection():ExpectNotification(videoService.notif, { available = false })
  :Do(function(_, data) common.log(common.ld[2], data.method, data.params.available) end)
  common.getHMIConnection():ExpectNotification(audioService.notif, { available = false })
  :Do(function(_, data) common.log(common.ld[2], data.method, data.params.available) end)
  common.getHMIConnection():ExpectRequest(videoService.stopRpc, { appID = common.getHMIId() })
  :Do(function(_, data)
      common.log(common.ld[2], data.method)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      common.log(common.ld[3], "SUCCESS:", data.method)
    end)
  common.getHMIConnection():ExpectRequest(audioService.stopRpc, { appID = common.getHMIId() })
  :Do(function(_, data)
      common.log(common.ld[2], data.method)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      common.log(common.ld[3], "SUCCESS:", data.method)
    end)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIId(), unexpectedDisconnect = true })
  :Do(function() common.log(common.ld[2], "OnAppUnregistered") end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("App starts video and audio streaming", appStartStreaming)
runner.Step("Unexpected disconnect", unexpectedDisconnect)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
