---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3412
---------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to proceed with Alert requests for 2 streaming apps
--
-- Steps:
-- 1. Two Navi apps are registered: App_1 and App_2
-- 2. App_1 is activated and starts streaming
-- 3. App_1 sends a few Alert requests
-- SDL does:
--  - proceed with requests successfully
-- 4. App_2 is activated and starts streaming (App_1 stops streaming)
-- 5. App_2 sends a few Alert requests
-- SDL does:
--  - proceed with requests successfully
-- 6. Do a few iterations of steps 2-5
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local numOfAttempts = 10
local numOfApps = 2
local numOfAlerts = 5
local filePath = "files/SampleVideo_5mb.mp4"
local videoService = 11

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3
for i = 1, numOfApps do
  common.app.getParams(i).appHMIType = { "NAVIGATION" }
  common.app.getParams(i).isMediaApplication = false
end

--[[ Local Functions ]]
local function startService(pAppId)
  common.mobile.getSession(pAppId):StartService(videoService)
  common.hmi.getConnection():ExpectRequest("Navigation.StartStream", { appID = common.app.getHMIId(pAppId) })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      utils.cprint(33, "SDL sends Navigation.StartStream to HMI")
    end)
end

local function startStreaming(pAppId)
  common.mobile.getSession(pAppId):StartStreaming(videoService, filePath, 160*1024)
  common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
  utils.cprint(33, "Streaming...")
  common.run.wait(200)
end

local function stopStreaming(pAppId)
  common.mobile.getSession(pAppId):StopStreaming(filePath)
  common.run.wait(200)
end

local function stopService(pAppId)
  common.getMobileSession(pAppId):StopService(videoService)
end

local function sendAlert(pAppId)
  local params = {
    alertText1 = "alertText1",
    ttsChunks = {
      { text = "TTSChunk", type = "TEXT" }
    }
  }
  local cid = common.mobile.getSession(pAppId):SendRPC("Alert", params)
  common.hmi.getConnection():ExpectRequest("UI.Alert")
  :Do(function(_, data)
      local function response()
        common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      common.run.runAfter(response, 500)
    end)
  common.hmi.getConnection():ExpectRequest("TTS.Speak")
  :Do(function(_, data)
      common.getHMIConnection():SendNotification("TTS.Started")
      local function response()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      common.run.runAfter(response, 1000)
    end)

  common.hmi.getConnection():ExpectRequest("TTS.StopSpeaking")
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.mobile.getSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

for n = 1, numOfApps do
  runner.Step("Register App " .. n, common.app.register, { n })
  runner.Step("PolicyTableUpdate", common.ptu.policyTableUpdate)
end

runner.Title("Test")
for a = 1, numOfAttempts do
  runner.Title("Attempt " .. a)
  for n = 1, numOfApps do
    runner.Title("App " .. n)
    runner.Step("Activate App", common.app.activate, { n })
    runner.Step("App Start video service", startService, { n })
    runner.Step("App Start video streaming", startStreaming, { n })
    for i = 1, numOfAlerts do
      runner.Step("App sends Alert " .. i, sendAlert, { n })
    end
    runner.Step("App stops streaming", stopStreaming, { n })
    runner.Step("App stops service", stopService, { n })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
