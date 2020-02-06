---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3160
-- Description: SDL stops streaming data by timeout when no new data from mobile received
--
-- Steps:
-- 1. Start SDL, HMI, connect Mobile device
-- 2. Activate App and start service (Audio/Video)
-- 3. App Start Streaming short file (duration 15 seconds) with a big bandwidth
-- SDL does:
--   - send "Navigation.OnVideoDataStreaming", { available = true } to HMI
--   - not send "Navigation.OnVideoDataStreaming", { available = false } to HMI during streaming
--   - send "Navigation.OnVideoDataStreaming", { available = false } to HMI after finish streaming
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Apps Configuration ]]
common.app.getParams(1).appHMIType = { "NAVIGATION" }

--[[ Local Functions ]]
local function startService(pService, pAppId)
  if not pAppId then pAppId = 1 end
  common.mobile.getSession(pAppId):StartService(pService)
  if pService == 10 then
    common.hmi.getConnection():ExpectRequest("Navigation.StartAudioStream")
    :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  elseif pService == 11 then
    common.hmi.getConnection():ExpectRequest("Navigation.StartStream")
    :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  else
    utils.cprint( 31, "Service for opening is not set")
  end
end

local function startStreaming(pService, pFile, pAppId)
  if not pAppId then pAppId = 1 end
  common.mobile.getSession(pAppId):StartStreaming(pService, pFile, 190*1024)
  if pService == 11 then
    common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
    common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
    :Times(0)
  else
    common.hmi.getConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = true })
    common.hmi.getConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = false })
    :Times(0)
  end
  utils.cprint(33, "Streaming...")
  utils.wait(15000)
end

local function stopStreaming(pService, pFile, pAppId)
  if not pAppId then pAppId = 1 end
  common.mobile.getSession(pAppId):StopStreaming(pFile)
  if pService == 11 then
    common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
  else
    common.hmi.getConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = false })
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Start audio service", startService, { 10 })
runner.Step("App start audio streaming", startStreaming, { 10, "files/MP3_123kb.mp3" })
runner.Step("App stop audio streaming", stopStreaming, { 10, "files/MP3_123kb.mp3" })

runner.Step("Start video service", startService, { 11 })
runner.Step("Start video streaming", startStreaming, { 11, "files/SampleVideoShort.mp4" })
runner.Step("Stop video streaming", stopStreaming, { 11, "files/SampleVideoShort.mp4" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
