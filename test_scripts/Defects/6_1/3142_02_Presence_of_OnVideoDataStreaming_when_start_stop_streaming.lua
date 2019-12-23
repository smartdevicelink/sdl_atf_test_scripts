---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3142
--
-- Steps:
-- 1. Set VideoDataStoppedTimeout = 1000 in SDL .INI file
-- 2. Start SDL, HMI, connect Mobile device
-- 3. Register PROJECTION application
-- 4. Activate App and start Video streaming
-- 5. Stop streaming of the data
-- SDL does:
--   - start VideoDataStoppedTimeout timeout
--   - send Navi.OnVideoDataStreaming(false) once timeout is expired
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Defects/6_1/common_3139_3140_3142")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Apps Configuration ]]
common.app.getParams(1).appHMIType = { "PROJECTION" }

--[[ Local Functions ]]
local ts = common.timestamp

local function stopStreaming()
  common.stopStreaming(1)
  ts("StreamingStop", "hmi")
end

local function startStreaming(pAppId, pServiceId)
  common.mobile.getSession(pAppId):StartService(pServiceId)
  :Do(function()
      common.mobile.getSession(pAppId):StartStreaming(pServiceId, common.streamFiles[pAppId], 160*1024)
      common.log("App " .. pAppId .." starts streaming ...")
      ts("StreamingStart", "hmi")
      common.streamingStatus[pAppId] = true
    end)
  common.hmi.getConnection():ExpectRequest("Navigation.StartStream", { appID = common.app.getHMIId(pAppId) })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

local function startAndStopStreaming()
  common.hmi.getConnection():ExpectNotification("Navigation.OnVideoDataStreaming",
    { available = true }, { available = false })
  :Do(function(e)
      if e.occurences == 1 then ts("Navi.OnVideoDataStreaming_true", "hmi") end
      if e.occurences == 2 then ts("Navi.OnVideoDataStreaming_false", "hmi") end
    end)
  :Times(2)
  startStreaming(1, 11)
  common.run.runAfter(stopStreaming, 2000)
  common.wait(4000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("App starts video streaming and stops in 2 sec", startAndStopStreaming)

runner.Step("Verify timeout for Navi.OnVideoDataStreaming_true", common.checkTimeout,
  { "StreamingStart", "Navi.OnVideoDataStreaming_true", 500 })
runner.Step("Verify timeout for Navi.OnVideoDataStreaming_false", common.checkTimeout,
  { "StreamingStop", "Navi.OnVideoDataStreaming_false", 500 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
