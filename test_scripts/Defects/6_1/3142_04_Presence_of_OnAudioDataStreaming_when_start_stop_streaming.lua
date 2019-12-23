---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3142
--
-- Steps:
-- 1. Set AudioDataStoppedTimeout = 1000 in SDL .INI file
-- 2. Start SDL, HMI, connect Mobile device
-- 3. Register PROJECTION application
-- 4. Activate App and start Audio streaming
-- 5. Stop streaming of the data
-- SDL does:
--   - start AudioDataStoppedTimeout timeout
--   - send Navi.OnAudioDataStreaming(false) once timeout is expired
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
      common.mobile.getSession(pAppId):StartStreaming(pServiceId, common.streamFiles[pAppId], 40*1024)
      common.log("App " .. pAppId .." starts streaming ...")
      ts("StreamingStart", "hmi")
      common.streamingStatus[pAppId] = true
    end)
  common.hmi.getConnection():ExpectRequest("Navigation.StartAudioStream", { appID = common.app.getHMIId(pAppId) })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

local function startAndStopStreaming()
  common.hmi.getConnection():ExpectNotification("Navigation.OnAudioDataStreaming",
    { available = true }, { available = false })
  :Do(function(e)
      if e.occurences == 1 then ts("Navi.OnAudioDataStreaming_true", "hmi") end
      if e.occurences == 2 then ts("Navi.OnAudioDataStreaming_false", "hmi") end
    end)
  :Times(2)
  startStreaming(1, 10)
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
runner.Step("App starts audio streaming and stops in 2 sec", startAndStopStreaming)

runner.Step("Verify timeout for Navi.OnAudioDataStreaming_true", common.checkTimeout,
  { "StreamingStart", "Navi.OnAudioDataStreaming_true", 500 })
runner.Step("Verify timeout for Navi.OnAudioDataStreaming_false", common.checkTimeout,
  { "StreamingStop", "Navi.OnAudioDataStreaming_false", 500 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
