---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3140
--
-- Steps:
-- 1. Set StopStreamingTimeout = 3000 in SDL .INI file
-- 2. Start SDL, HMI, connect Mobile device
-- 3. Register 2 NAVIGATION applications: App_1 and App_2
-- 4. Activate App_1 and start Video streaming
-- SDL does:
--   - start streaming successfully
-- 5. Deactivate App_1 and activate App_2
-- SDL does:
--   - stop streaming successfully
-- 6. Deactivate App_2, activate App_1 and start Video streaming (within StopStreamingTimeout)
-- SDL does:
--   - not send OnAppInterfaceUnregistered notification to App_1
--   - not send BC.OnAppUnregistered notification to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Defects/6_1/common_3139_3140_3142")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Apps Configuration ]]
common.app.getParams(1).appHMIType = { "NAVIGATION" }
common.app.getParams(2).appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local stopStreamingTimeout = 3000
local videoDataStoppedTimeout = 1000

--[[ Local Functions ]]
local log = common.log

local function activateApp2()
  local cid = common.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = common.app.getHMIId(2) })
  log("SDL->HMI ", "SDL.ActivateApp(2)")
  common.hmi.getConnection():ExpectResponse(cid)
  :Do(function()
      log("SDL->HMI ", "SUCCESS: SDL.ActivateApp")
    end)

  common.mobile.getSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", videoStreamingState = "STREAMABLE" })
  :Do(function()
      log("SDL->App2", "OnHMIStatus(FULL)")
    end)

  common.mobile.getSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", videoStreamingState = "NOT_STREAMABLE" })
  :Do(function()
      log("SDL->App1", "OnHMIStatus(NOT_STREAMABLE)")
    end)

  common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
  :Do(function()
      log("SDL->HMI ","Navi.OnVideoDataStreaming(false)")
    end)
  :Times(AtLeast(1)) -- number of occurrences may be >1 due to issue 3142

  common.hmi.getConnection():ExpectRequest("Navigation.StopStream", { appID = common.app.getHMIId(1)})
  :Do(function(_, data)
      log("SDL->HMI ","Navi.StopStream")
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      log("HMI->SDL ","SUCCESS: Navi.StopStream")
    end)

  common.mobile.getSession(1):ExpectEndService(11)
  :Do(function()
      log("SDL->App1", "EndService(VIDEO)")
      common.mobile.getSession(1):SendEndServiceAck(11)
      log("App1->SDL", "EndServiceAck")
      common.stopStreaming(1)
    end)
end

local function startStreaming()
  common.startStreaming(1, 11)
  common.mobile.getSession(1):ExpectNotification("OnAppInterfaceUnregistered"):Times(0)
  :Do(function()
      log("SDL->App1", "OnAppInterfaceUnregistered(PROT_VIO)")
    end)
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppUnregistered"):Times(0)
  :Do(function()
      log("SDL->HMI ","BC.OnAppUnregistered(App1)")
    end)
  common.wait(5000)
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
runner.Step("App 2 activated", activateApp2)
runner.Step("App 2 deactivated", common.deactivateApp, { 2 })
runner.Step("App 1 activated", common.activateApp, { 1 })
runner.Step("App 1 continue video streaming", startStreaming, { 1, 11 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
