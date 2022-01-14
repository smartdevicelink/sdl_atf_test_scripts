---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3831
---------------------------------------------------------------------------------------------------
-- Description: Check SDL calculates playback time based on 'samplingRate' and 'bitsPerSample'
-- provided by HMI
--
-- Steps:
-- 1. HMI provides some values for 'samplingRate' and 'bitsPerSample' within 'UI.GetCapabilities' response
-- 2. Navi App registers and starts streaming Audio
-- SDL does:
--  - send 'Navigation.OnAudioDataStreaming(true)' to HMI once streaming is started
--  - start internal timer based on data provided by HMI according to formula:
--    timeout = 1000 * data_size / (sampling_rate * bits_per_sample / 8) + latency
--  - send 'Navigation.OnAudioDataStreaming(false)' to HMI once timer expires
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local color = require("user_modules/consts").color
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [01] = { samplingRate = 8000, bitsPerSample = 8 },
  [02] = { samplingRate = 8000, bitsPerSample = 16 },
  [03] = { samplingRate = 16000, bitsPerSample = 8 },
  [04] = { samplingRate = 16000, bitsPerSample = 16 },
  [05] = { samplingRate = 22000, bitsPerSample = 8 },
  [06] = { samplingRate = 22000, bitsPerSample = 16 },
  [07] = { samplingRate = 44000, bitsPerSample = 8 },
  [08] = { samplingRate = 44000, bitsPerSample = 16 }
}
local serviceId = 10
local streamingFile = "files/MP3_123kb.mp3"
local samplingRateMap = {
  [8000] = "8KHZ",
  [16000] = "16KHZ",
  [22000] = "22KHZ",
  [44000] = "44KHZ"
}
local bitsPerSampleMap = {
  [8] = "8_BIT",
  [16] = "16_BIT"
}

--[[ Local Functions ]]
local function getHMIParams(pSamplingRate, pBitsPerSample)
  local params = hmi_values.getDefaultHMITable()
  local pcmStreamCapabilities = params.UI.GetCapabilities.params.pcmStreamCapabilities
  pcmStreamCapabilities.samplingRate = samplingRateMap[pSamplingRate]
  pcmStreamCapabilities.bitsPerSample = bitsPerSampleMap[pBitsPerSample]
  return params
end

local function startAudioService()
  common.getHMIConnection():ExpectRequest("Navigation.StartAudioStream")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.getMobileSession():StartService(serviceId)
end

local function startAudioStreaming(pSamplingRate, pBitsPerSample)
  local start_ts = timestamp()
  common.getHMIConnection():ExpectNotification("Navigation.OnAudioDataStreaming",
    { available = true }, { available = false })
  :ValidIf(function(exp)
      if exp.occurences == 2 then
        local streamDelay = 500
        local latency = 500
        local data_size = 125309
        local sampling_rate = pSamplingRate
        local bits_per_sample = pBitsPerSample
        local expDuration = math.floor(1000 * data_size / (sampling_rate * bits_per_sample / 8) + latency + streamDelay)
        local actDuration = timestamp() - start_ts
        utils.cprint(color.magenta, "Duration expected: " .. tostring(expDuration)
          .. ", actual: " .. tostring(actDuration))
        if actDuration < expDuration - latency or actDuration > expDuration + latency then
          return false, "Unexpected streaming duration"
        end
      end
      return true
    end)
  :Times(2)
  :Timeout(20000)
  common.getMobileSession():StartStreaming(serviceId, streamingFile, 80*1024)
end

local function StopAudioStreaming()
  common.getMobileSession():StopStreaming(streamingFile)
end

--[[ Scenario ]]
for id, tc in utils.spairs(testCases) do
  runner.Title("Test Case [" .. id .. "] samplingRate: " .. tc.samplingRate .. ", bitsPerSample: " .. tc.bitsPerSample)
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start,
    { getHMIParams(tc.samplingRate, tc.bitsPerSample) })
  runner.Step("Register App", common.registerApp)
  runner.Step("Activate App", common.activateApp)
  runner.Step("Start audio service", startAudioService)

  runner.Title("Test")
  runner.Step("Start audio streaming", startAudioStreaming, { tc.samplingRate, tc.bitsPerSample })

  runner.Title("Postconditions")
  runner.Step("Stop audio streaming", StopAudioStreaming)
  runner.Step("Stop SDL", common.postconditions)
end
