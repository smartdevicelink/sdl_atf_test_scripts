---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- Mobile application sends request with isTemplate = true
-- SDL must:
-- send request to HMI with isTemplate = true
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Image_template/commonImageTemplate')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Adding PNG file via PutFile", common.putFile)

runner.Title("Test")
runner.Step("AddCommand with isTemplate = true", common.addCommand, { true })
runner.Step("Alert with isTemplate = true in SoftButtons", common.alert, { true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
