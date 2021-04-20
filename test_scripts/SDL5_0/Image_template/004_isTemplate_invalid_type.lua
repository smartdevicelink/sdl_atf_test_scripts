---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- Mobile application sends request with wrong type of isTemplate
-- SDL must:
-- respond with INVALID_DATA resultCode to mobile application
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
runner.Step("AddCommand with isTemplate = 123", common.rpcInvalidData, { 123, "AddCommand" } )
runner.Step("Alert with isTemplate = '123' in SoftButtons", common.rpcInvalidData, { "123", "Alert" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
