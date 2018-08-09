---------------------------------------------------------------------------------------------------
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- Check that SDL does not application registration with duplicate name with appID same as for app1
-- In case:
-- 1) Second mobile app registers with same appName and appID same as the first mobile app.
-- SDL does:
-- 1) Not register the second mobile app and return DUPLICATE_NAME response to the second mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsApp1 = common.getRequestParams(1)
local paramsApp2 = common.getRequestParams(2)
paramsApp2.appName = paramsApp1.appName
paramsApp2.appID = paramsApp1.appID

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("App registration", common.registerApp, { 1, paramsApp1})

runner.Title("Test")
runner.Step("Second app with a duplicate appName and appID same as for the firs app", common.unsuccessRAI,
	{ 2, paramsApp2, "DUPLICATE_NAME" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
