---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0041-appicon-resumption.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) SDL, HMI are started.
-- 2) Mobile application is registered and sets custom icon via sending PutFile and valid SetAppIcon request.
-- 3) App re-sets custom icon via sending PutFile and valid SetAppIcon request.
-- 4) App is re-registered.
-- SDL does:
-- 1) Successfully register application
-- 2) Successful processes PutFile and SetAppIcon requests.
-- 3) Respons with result code "SUCCESS" and "iconResumed" = true for RAI request. Corresponding custom icon is resumed.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SetAppIcon/commonIconResumed')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams1 = {
  syncFileName = "icon.png"
}

local requestParams2 = {
  syncFileName = "action.png"
}

local requestUiParams1 = {
	syncFileName = {
		imageType = "DYNAMIC",
		value = common.getPathToFileInStorage(requestParams1.syncFileName)
	}
}

local requestUiParams2 = {
	syncFileName = {
		imageType = "DYNAMIC",
		value = common.getPathToFileInStorage(requestParams2.syncFileName)
	}
}

local allParamsSet1 = {
  requestParams = requestParams1,
  requestUiParams = requestUiParams1
}

local allParamsSet2 = {
  requestParams = requestParams2,
  requestUiParams = requestUiParams2
}

local PutFileParams = {
    syncFileName = "action.png",
    fileType = "GRAPHIC_PNG",
 }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration with iconResumed = false", common.registerAppWOPTU, { 1, false })
runner.Step("Upload icon file1", common.putFile)
runner.Step("SetAppIcon1", common.setAppIcon, { allParamsSet1 } )

runner.Step("Upload icon file2", common.putFile, {PutFileParams})
runner.Step("SetAppIcon2", common.setAppIcon, { allParamsSet2 } )

runner.Step("App unregistration", common.unregisterAppInterface, { 1 })
runner.Step("App registration with iconResumed = true", common.registerAppWOPTU, { 1, true, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
