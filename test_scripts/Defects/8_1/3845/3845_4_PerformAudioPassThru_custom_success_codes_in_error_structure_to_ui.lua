---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3845
---------------------------------------------------------------------------------------------------
-- Description: SDL responds with success=false to mobile app in case of receiving the next result codes from HMI
-- in error structure: "UNSUPPORTED_RESOURCE", "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE", "TRUNCATED_DATA"
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. Mobile app is registered and activated
-- 3. Mobile app requests PerformAudioPassThru RPC
-- 4. HMI responds with SUCCESS result to TTS.Speak request
-- 5. HMI responds to UI.PerformAudioPassThru request in error structure with one of result code:
--  "UNSUPPORTED_RESOURCE", "WARNINGS", "RETRY", "SAVED", "WRONG_LANGUAGE", "TRUNCATED_DATA"
-- SDL does:
-- - send PerformAudioPassThru(resultCode = <received result code>, success = false) response to mobile app
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
for tc, resultCode in ipairs(common.tcs) do
  local resultCodes = {
    speak = "SUCCESS",
    performAudioPassThru = resultCode,
    general = resultCode
  }
  runner.Title("Test case [" .. string.format("%02d", tc) .. "]: '" .. tostring(resultCode) .. "'")
  runner.Step("PerformAudioPassThru response with success=false", common.performAudioPassThruErrorResponse,
    { resultCodes })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
