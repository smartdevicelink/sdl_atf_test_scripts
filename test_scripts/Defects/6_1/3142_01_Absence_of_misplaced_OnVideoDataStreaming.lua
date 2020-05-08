---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3142
--
-- Steps:
-- 1. Set StopStreamingTimeout = 3000 and VideoDataStoppedTimeout = 3000 in SDL .INI file
-- 2. Start SDL, HMI, connect Mobile device
-- 3. Register 2 NAVIGATION applications: App_1 and App_2
-- 4. Activate App_1 and start Video streaming
-- 5. Deactivate App_1 (streaming still continue since app has STREAMABLE state)
-- 6. Activate App_2 and start Video streaming
-- 7. App_1 and App_2 continue streaming data within 'StopStreamingTimeout' timeout
-- SDL does:
--   - switch streaming between apps and provides HMI with streaming data from App_2
--     - sends 'Navi.StopStream' for App_1
--     - sends Navi.OnVideoDataStreaming(false)
--     - sends 'Navi.StartStream' for App_2
--     - sends Navi.OnVideoDataStreaming(true)
--   - not unregister App_1 since timeout is not yet expired
-- 8. App_1 stops streaming within 'StopStreamingTimeout' timeout
-- SDL does:
--   - not send Navi.OnVideoDataStreaming(false) notification to HMI since App_2 still continue streaming
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
  common.hmi.getConnection():ExpectRequest("Navigation.StopStream", { appID = common.app.getHMIId(pAppId)})
  :Do(function(_, data)
      common.log("Navigation.StopStream for App " .. pAppId)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

local function startStreaming(pAppId, pServiceId)
  common.mobile.getSession(pAppId):StartService(pServiceId)
  :Do(function()
      common.mobile.getSession(pAppId):StartStreaming(pServiceId, common.streamFiles[pAppId], 160*1024)
      common.log("App " .. pAppId .." starts streaming ...")
      common.streamingStatus[pAppId] = true
    end)
  common.hmi.getConnection():ExpectRequest("Navigation.StartStream", { appID = common.app.getHMIId(pAppId) })
  :Do(function(_, data)
      common.log("Navigation.StartStream for App " .. pAppId)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

local function activateApp2()
  local cid = common.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = common.app.getHMIId(2) })
  common.hmi.getConnection():ExpectResponse(cid)
  common.mobile.getSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", videoStreamingState = "STREAMABLE" })
  :Do(function()
      stopStreaming(1, 11)
      startStreaming(2, 11)
    end)
  common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming",
    { available = false }, { available = true })
  :Times(2)
end

local function stopStreamingWONotification()
  common.stopStreaming(1)
  common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming"):Times(0)
  common.wait(5000)
end

local function stopStreamingWithNotification()
  common.stopStreaming(2)
  common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
  common.wait(5000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, {{ StopStreamingTimeout = 3000, VideoDataStoppedTimeout = 3000 }})
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App 1", common.registerApp, { 1 })
runner.Step("Register App 2", common.registerApp, { 2 })
runner.Step("Activate App 1", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("App 1 start video streaming", common.startStreaming, { 1, 11 })
runner.Step("App 1 deactivated", common.deactivateApp, { 1 })
runner.Step("App 2 activated", activateApp2)
runner.Step("App 1 stop video streaming without notification", stopStreamingWONotification)
runner.Step("App 2 stop video streaming with notification", stopStreamingWithNotification)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
