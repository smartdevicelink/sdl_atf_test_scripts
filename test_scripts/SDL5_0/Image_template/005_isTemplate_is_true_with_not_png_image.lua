---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- Mobile application sends request with isTemplate = true and not png image
-- SDL must:
-- send request with received paramters to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Image_template/commonImageTemplate')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local fileName = "action.jpeg"

local putFileParams = {
	requestParams = {
	    syncFileName = fileName,
	    fileType = "GRAPHIC_JPEG",
	},
	filePath = "files/" .. fileName
}

local pathToFile = common.getPathToFileInStorage(fileName)

local paramsAlert = common.alertParams()
paramsAlert.requestParams.softButtons[1].image.value = fileName
paramsAlert.requestParams.softButtons[1].image.isTemplate = true
paramsAlert.responseUiParams.softButtons[1].image.value = pathToFile
paramsAlert.responseUiParams.softButtons[1].image.isTemplate = true

local paramsAddCommand = common.addCommandParams()
paramsAddCommand.requestParams.cmdIcon.value = fileName
paramsAddCommand.requestParams.cmdIcon.isTemplate = true
paramsAddCommand.responseUiParams.cmdIcon.value = pathToFile
paramsAddCommand.responseUiParams.cmdIcon.isTemplate = true

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Adding JPEG file via PutFile", common.putFile, { putFileParams })
runner.Step("AddCommand with isTemplate = true with jpeg icon", common.rpcWithCustomResultCode,
	{ "AddCommand", paramsAddCommand, "WARNINGS", true })
runner.Step("Alert with isTemplate = true and jpeg icon in SoftButtons", common.rpcWithCustomResultCode,
	{ "Alert", paramsAlert, "WARNINGS", true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
