---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3174
--
-- Description: SDL should stop video streaming and notify HMI if an App is Force Closed
--
-- Pre-conditions:
-- 1. Start SDL, HMI, connect Mobile device
-- 2. Register NAVIGATION (App) application
-- 3. Activate App and start video streaming
--
-- Steps:
-- 1. Force Close App from Mobile (Close session)
-- SDL does:
--  - send Navigation.OnVideoDataStreaming("available":false) notification to HMI
--  - send Navigation.StopStream(App) request to HMI
--  - send BasicCommunication.OnAppUnregistered(App) notification to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appHMIType = "NAVIGATION"
local filePath = "files/SampleVideo_5mb.mp4"
local videoService = 11

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3
config.application1.registerAppInterfaceParams.appHMIType = { appHMIType }

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  pTbl.policy_table.app_policies[common.app.getParams().fullAppID].AppHMIType = { appHMIType }
end

local function startService()
  common.mobile.getSession():StartService(videoService)
  common.hmi.getConnection():ExpectRequest("Navigation.StartStream", { appID = common.app.getHMIId() })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      utils.cprint(33, "SDL sends Navigation.StartStream to HMI")
    end)
end

local function startStreaming()
  common.mobile.getSession():StartStreaming(videoService, filePath, 160*1024)
  common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
  utils.cprint(33, "Streaming...")
  common.run.wait(1000)
end

local function forceCloseApp()
  local hmi = common.hmi.getConnection()
  local hmiAppId = common.app.getHMIId()
  hmi:ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
  hmi:ExpectRequest("Navigation.StopStream", { appID = hmiAppId })
  :Do(function(_, data)
      hmi:SendResponse(data.id, data.method, "SUCCESS", { })
      utils.cprint(33, "SDL sends Navigation.StopStream to HMI")
    end)
  hmi:ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true, appID = hmiAppId })
  common.mobile.closeSession()
  utils.cprint(33, "App closes session")
  common.run.wait(2000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.app.register)
runner.Step("PolicyTableUpdate with HMI types", common.ptu.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.app.activate)
runner.Step("Start video service", startService)
runner.Step("Start video streaming", startStreaming)

runner.Title("Test")
runner.Step("Force close App", forceCloseApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
