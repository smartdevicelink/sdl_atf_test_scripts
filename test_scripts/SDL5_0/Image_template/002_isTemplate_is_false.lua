---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- Mobile application sends request with isTemplate = false
-- SDL must:
-- send isTemplate = false to HMI
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
runner.Step("AddCommand with isTemplate = false", common.addCommand, { false })
runner.Step("Alert with isTemplate = false in SoftButtons", common.alert, { false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
