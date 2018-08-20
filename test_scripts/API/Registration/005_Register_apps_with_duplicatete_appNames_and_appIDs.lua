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
-- 1) Second mobile app registers with same appName and appID same as the first mobile app.
-- SDL does:
-- 1) Not register the second mobile app and returnes DUPLICATE_NAME response to the second mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Registration/commonRAI')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appID = "1"
local appName = "Test Application"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("Second app with a duplicate appName and appID same as for the firs app", common.duplicateAppName, { appID, appName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
