---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3139
--
-- Steps:
-- 1. Set StopStreamingTimeout = 3000 in SDL .INI file
-- 2. Start SDL, HMI, connect Mobile device
-- 3. Register PROJECTION (App_1) and NAVIGATION (App_2) applications
-- 4. Activate App_1 and start Video streaming
-- 5. Deactivate App_1 (streaming still continue since app has STREAMABLE state)
-- 6. Activate App_2
-- SDL does:
--   - send OnHMIStatus(FULL, STREAMABLE) notification to App_2
--   - send OnHMIStatus(LIMITED, NOT_STREAMABLE) notification to App_1
--   - send Navi.OnVideoDataStreaming(false) notification to HMI
--   - start 1st 'StopStreamingTimeout' timeout
-- Once timeout is expired SDL does:
--   - send Navi.StopStream(App_1) request to HMI
--   - send EndService(VIDEO) request to App_1
--   - start 2nd 'StopStreamingTimeout' timeout
-- 7. App_1 stops streaming but dos not send EndServiceAck within 2nd 'StopStreamingTimeout' timeout
-- Once timeout is expired SDL does:
--   - send OnAppInterfaceUnregistered(PROTOCOL_VIOLATION) notification to App_1
--   - send BC.OnAppUnregistered(unexpectedDisconnect=false) notification to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Defects/6_1/common_3139_3140_3142")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Apps Configuration ]]
common.app.getParams(1).appHMIType = { "PROJECTION" }
common.app.getParams(2).appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local stopStreamingTimeout = 3000
local videoDataStoppedTimeout = 1000

--[[ Local Functions ]]
local log = common.log
local ts = common.timestamp

local function activateApp2()
  local cid = common.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = common.app.getHMIId(2) })
  log("SDL->HMI ", "SDL.ActivateApp(2)")
  ts("ActivateApp")
  common.hmi.getConnection():ExpectResponse(cid)
  :Do(function()
      log("SDL->HMI ", "SUCCESS: SDL.ActivateApp")
    end)

  common.mobile.getSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", videoStreamingState = "STREAMABLE" })
  :Do(function()
      log("SDL->App2", "OnHMIStatus(FULL)")
      ts("OnHMIStatus_Full", "app2")
    end)

  common.mobile.getSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", videoStreamingState = "NOT_STREAMABLE" })
  :Do(function()
      log("SDL->App1", "OnHMIStatus(NOT_STREAMABLE)")
      ts("OnHMIStatus_Not_Streamable", "app1")
    end)

  common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
  :DoOnce(function()
      log("SDL->HMI ","Navi.OnVideoDataStreaming(false)")
      ts("Navi.OnVideoDataStreaming", "hmi")
    end)

  common.hmi.getConnection():ExpectRequest("Navigation.StopStream", { appID = common.app.getHMIId(1)})
  :Do(function(_, data)
      log("SDL->HMI ","Navi.StopStream")
      ts("Navi.StopStream", "hmi")
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      log("HMI->SDL ","SUCCESS: Navi.StopStream")
    end)

  common.mobile.getSession(1):ExpectEndService(11)
  :Do(function()
      log("SDL->App1", "EndService(VIDEO)")
      ts("EndService", "app1")
      common.stopStreaming(1)
      -- App_1 doesn't send EndServiceAck
    end)

  common.mobile.getSession(1):ExpectNotification("OnAppInterfaceUnregistered",
    { reason = "PROTOCOL_VIOLATION" })
  :Do(function()
      log("SDL->App1", "OnAppInterfaceUnregistered(PROT_VIO)")
      ts("OnAppInterfaceUnregistered", "app1")
    end)

  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = false, appID = common.app.getHMIId(1) })
  :Do(function()
      log("SDL->HMI ","BC.OnAppUnregistered(App1)")
      ts("BC.OnAppUnregistered", "hmi")
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean and setup environment", common.preconditions,
  { { StopStreamingTimeout = stopStreamingTimeout, VideoDataStoppedTimeout = videoDataStoppedTimeout } })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App 1", common.registerApp, { 1 })
runner.Step("Register App 2", common.registerApp, { 2 })
runner.Step("Activate App 1", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("App 1 start video streaming", common.startStreaming, { 1, 11 })
runner.Step("App 1 deactivated", common.deactivateApp, { 1 })
runner.Step("App 2 activated, App 1 unregistered with PROTOCOL_VIOLATION", activateApp2)
runner.Step("App 2 start video streaming", common.startStreaming, { 2, 11 })

runner.Step("Verify timeout for OnHMIStatus_Not_Streamable", common.checkTimeout,
  { "ActivateApp", "OnHMIStatus_Not_Streamable", 0 })
runner.Step("Verify timeout for EndService", common.checkTimeout,
  { "ActivateApp", "EndService", stopStreamingTimeout })
runner.Step("Verify timeout for OnAppInterfaceUnregistered", common.checkTimeout,
  { "ActivateApp", "OnAppInterfaceUnregistered", stopStreamingTimeout * 2 })

runner.Step("Verify timeout for Navi.OnVideoDataStreaming", common.checkTimeout,
  { "ActivateApp", "Navi.OnVideoDataStreaming", videoDataStoppedTimeout })
runner.Step("Verify timeout for Navi.StopStream", common.checkTimeout,
  { "ActivateApp", "Navi.StopStream", stopStreamingTimeout })
runner.Step("Verify timeout for BC.OnAppUnregistered", common.checkTimeout,
  { "ActivateApp", "BC.OnAppUnregistered", stopStreamingTimeout * 2 })

runner.Step("Check App1 messages sequence", common.checkSequence,
 { "app1", { "ActivateApp", "OnHMIStatus_Not_Streamable", "EndService", "OnAppInterfaceUnregistered" } })
runner.Step("Check App2 messages sequence", common.checkSequence,
 { "app2", { "ActivateApp", "OnHMIStatus_Full" } })
runner.Step("Check HMI messages sequence", common.checkSequence,
 { "hmi", { "ActivateApp", "Navi.OnVideoDataStreaming", "Navi.StopStream", "BC.OnAppUnregistered" } })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
