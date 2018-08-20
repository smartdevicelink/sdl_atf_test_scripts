---------------------------------------------------------------------------------------------------
-- Regression check
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) The mobile application is registered with supported ttsName types.
-- SDL does:
-- 1) Successfully register the mobile application with resultСode: "SUCCESS".
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local typeParams = {
    "PRE_RECORDED",
    "SAPI_PHONEMES",
    "LHPLUS_PHONEMES",
    "SILENCE"
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)

for _, v in ipairs (typeParams) do
    runner.Title("Test")
    runner.Step("Registered with ttsName_type " .. _, common.registerApp, { 1, v })
    runner.Step("Application unregistered", common.unregisterAppInterface)
    runner.Step("Clean sessions", common.cleanSessions)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
