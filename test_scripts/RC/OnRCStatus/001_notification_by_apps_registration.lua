---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC app1 and RC app2 are registered
-- SDL must:
-- 1) Send OnRCStatus notifications to registered mobile application with allowed = true
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("OnRCStatus notification by app registration", common.registerRCApplication, { 1 })
runner.Step("OnRCStatus notification by registration 2nd app", common.registerRCApplication, { 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
