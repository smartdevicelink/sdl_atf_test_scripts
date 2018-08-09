---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) The mobile application registered with supported ttsName types.
-- SDL does:
-- 1) Successfully registers the mobile application with resultСode: "SUCCESS".
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local typeParams = {
    PRE_RECORDED = "PRE_RECORDED",
    SAPI_PHONEMES = "SAPI_PHONEMES",
    LHPLUS_PHONEMES = "LHPLUS_PHONEMES",
    SILENCE = "SILENCE"
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

for k, v in pairs (typeParams) do
runner.Title("Test")
runner.Step("Registered with ttsName_type " .. k, common.registerApp, {v})
runner.Step("Application unregistered", common.unregisterAppInterface)
runner.Step("Clean sessions", common.cleanSessions)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
