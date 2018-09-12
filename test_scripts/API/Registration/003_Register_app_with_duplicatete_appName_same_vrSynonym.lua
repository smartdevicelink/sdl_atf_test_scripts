---------------------------------------------------------------------------------------------------
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) The second mobile app tries to register with a duplicate "appName" same as the "vrSynonyms" for the first app.
-- SDL does:
-- 1) Not register the second mobile app and returnes DUPLICATE_NAME response to the second mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsApp1 = common.getRequestParams(1)
local paramsApp2 = common.getRequestParams(2)
paramsApp2.appName = paramsApp1.vrSynonyms[1]

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("App1 registration", common.registerApp, { 1, paramsApp1 })

runner.Title("Test")
runner.Step("App2 registration with duplicate name", common.unsuccessRAI, { 2, paramsApp2, "DUPLICATE_NAME" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
