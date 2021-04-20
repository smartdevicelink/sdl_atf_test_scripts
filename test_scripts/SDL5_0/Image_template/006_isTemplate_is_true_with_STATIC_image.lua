---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- Mobile application sends request with isTemplate = true and STATIC image type
-- SDL must:
-- send request with received paramters to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Image_template/commonImageTemplate')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local fileName = "icon.png"

local paramsAddCommand = common.addCommandParams()
paramsAddCommand.requestParams.cmdIcon.imageType = "STATIC"
paramsAddCommand.requestParams.cmdIcon.value = fileName
paramsAddCommand.requestParams.cmdIcon.isTemplate = true
paramsAddCommand.responseUiParams.cmdIcon.value = fileName
paramsAddCommand.responseUiParams.cmdIcon.isTemplate = true
paramsAddCommand.responseUiParams.cmdIcon.imageType = "STATIC"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Adding PNG file via PutFile", common.putFile)

runner.Title("Test")
runner.Step("AddCommand with isTemplate = true with STATIC image type", common.rpcWithCustomResultCode,
	{ "AddCommand", paramsAddCommand, "UNSUPPORTED_RESOURCE", true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
