---------------------------------------------------------------------------------------------------
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- Check that SDL does not the  application registration second with same appName and appID same as for first application
-- In case:
-- 1) When two applications are registered with one appID.
-- SDL does:
-- 1) Send APPLICATION_REGISTERED_ALREADY code when the app sends RegisterAppInterface within the same connection
--    after RegisterAppInterface has been already sent and not unregistered yet.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsApp1 = common.getRequestParams(1)
local paramsApp2 = common.getRequestParams(1)
paramsApp2.appID = paramsApp1.appID

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register app", common.registerApp, { 1, paramsApp1})

runner.Title("Test")
runner.Step("Register_applications_with_one_appID", common.unsuccessRAI,
	{ 2, paramsApp2, "APPLICATION_REGISTERED_ALREADY"})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
