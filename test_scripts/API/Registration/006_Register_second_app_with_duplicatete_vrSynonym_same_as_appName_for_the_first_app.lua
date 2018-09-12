---------------------------------------------------------------------------------------------------
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) The second mobile app tries to register when its "vrSynonyms" matches the "appName" for the first app.
-- SDL does:
-- 1) Not register and return DUPLICATE_NAME response to the second mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsApp1 = common.getRequestParams(1)
local paramsApp2 = common.getRequestParams(2)
paramsApp2.vrSynonyms = { paramsApp1.appName }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("App registration", common.registerApp, { 1, paramsApp1 })

runner.Title("Test")
runner.Step("Second app with a duplicate name vrSynonyms same as the appName for the first app",
	common.unsuccessRAI, { 2, paramsApp2, "DUPLICATE_NAME" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
