---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3845
---------------------------------------------------------------------------------------------------
-- Description: SDL responds with success = true to mobile app in case
-- HMI responds with not "SUCCESS" result code to TTS.Speak and UI.PerformAudioPassThru requests
-- in result structure
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
-- 3. Mobile app requests PerformAudioPassThru RPC
-- 4. HMI responds to TTS.Speak and UI.PerformAudioPassThr requests in result structure with one of result code:
--  "UNSUPPORTED_RESOURCE", "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE", "TRUNCATED_DATA"
-- SDL does:
-- - send PerformAudioPassThru(resultCode = <result code received for UI part>, success = true) response to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/8_1/3845/common_3845')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, resultCodeUI in ipairs(common.tcs) do
  for _, resultCodeSpeak in ipairs(common.tcs) do
    local responses = {
      speak = { code = resultCodeSpeak, structure = common.responsesStructures.result },
      performAudioPassThru = { code = resultCodeUI, structure = common.responsesStructures.result },
      general = resultCodeUI
    }
    runner.Title("Test case: '" .. tostring(resultCodeSpeak) .. "' to tts, '" .. tostring(resultCodeUI) .. "' to ui")
    runner.Step("PerformAudioPassThru response with success=true", common.performAudioPassThru, { responses })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
