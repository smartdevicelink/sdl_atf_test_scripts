---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3142
--
-- Steps:
-- 1. Set StopStreamingTimeout = 3000 and AudioDataStoppedTimeout = 3000 in SDL .INI file
-- 2. Start SDL, HMI, connect Mobile device
-- 3. Register 2 NAVIGATION applications: App_1 and App_2
-- 4. Activate App_1 and start Audio streaming
-- 5. Deactivate App_1 (streaming still continue since app has STREAMABLE state)
-- 6. Activate App_2 and start Audio streaming
-- 7. App_1 and App_2 continue streaming data within 'StopStreamingTimeout' timeout
-- SDL does:
--   - switch streaming between apps and provides HMI with streaming data from App_2
--     - sends 'Navi.StopAudioStream' for App_1
--     - sends Navi.OnAudioDataStreaming(false)
--     - sends 'Navi.StartAudioStream' for App_2
--     - sends Navi.OnAudioDataStreaming(true)
--   - not unregister App_1 since timeout is not yet expired
-- 8. App_1 stops streaming within 'StopStreamingTimeout' timeout
-- SDL does:
--   - not send Navi.OnAudioDataStreaming(false) notification to HMI since App_2 still continue streaming
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Defects/6_1/common_3139_3140_3142")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Apps Configuration ]]
common.app.getParams(1).appHMIType = { "NAVIGATION" }
common.app.getParams(2).appHMIType = { "NAVIGATION" }

--[[ Local Functions ]]
local function stopStreaming(pAppId)
  common.hmi.getConnection():ExpectRequest("Navigation.StopAudioStream", { appID = common.app.getHMIId(pAppId)})
  :Do(function(_, data)
      common.log("Navigation.StopAudioStream for App " .. pAppId)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

local function startStreaming(pAppId, pServiceId)
  common.mobile.getSession(pAppId):StartService(pServiceId)
  :Do(function()
      common.mobile.getSession(pAppId):StartStreaming(pServiceId, common.streamFiles[pAppId], 40*1024)
      common.log("App " .. pAppId .." starts streaming ...")
      common.streamingStatus[pAppId] = true
    end)
  common.hmi.getConnection():ExpectRequest("Navigation.StartAudioStream", { appID = common.app.getHMIId(pAppId) })
    :Do(function(_, data)
      common.log("Navigation.StartAudioStream for App " .. pAppId)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

local function activateApp2()
  local cid = common.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = common.app.getHMIId(2) })
  common.hmi.getConnection():ExpectResponse(cid)
  common.mobile.getSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Do(function()
      stopStreaming(1, 10)
      startStreaming(2, 10)
    end)
  common.hmi.getConnection():ExpectNotification("Navigation.OnAudioDataStreaming",
    { available = false }, { available = true })
  :Times(2)
end

local function stopStreamingWONotification()
  common.stopStreaming(1)
  common.hmi.getConnection():ExpectNotification("Navigation.OnAudioDataStreaming"):Times(0)
  common.wait(5000)
end

local function stopStreamingWithNotification()
  common.stopStreaming(2)
  common.hmi.getConnection():ExpectNotification("Navigation.OnAudioDataStreaming", { available = false })
  common.wait(5000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, {{ StopStreamingTimeout = 3000, AudioDataStoppedTimeout = 3000 }})
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App 1", common.registerApp, { 1 })
runner.Step("Register App 2", common.registerApp, { 2 })
runner.Step("Activate App 1", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("App 1 start audio streaming", common.startStreaming, { 1, 10 })
runner.Step("App 1 deactivated", common.deactivateApp, { 1 })
runner.Step("App 2 activated", activateApp2)
runner.Step("App 1 stop audio streaming", stopStreamingWONotification)
runner.Step("App 2 stop audio streaming with notification", stopStreamingWithNotification)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
