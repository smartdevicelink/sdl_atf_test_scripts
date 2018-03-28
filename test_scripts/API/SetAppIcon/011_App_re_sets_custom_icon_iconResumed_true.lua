---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0041-appicon-resumption.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
-- Description:
-- In case:
-- 1) SDL, HMI are started.
-- 2) Mobile application is registered and sets custom icon via sending PutFile and valid SetAppIcon request.
-- 3) App re-sets custom icon via sending PutFile and valid SetAppIcon request.
-- 4) App is re-registered.
-- SDL does:
-- 1) Successfully registers application
-- 2) Successful processes PutFile and SetAppIcon requests.
-- 3) SDL respons with result code "SUCCESS" and "iconResumed" = true for RAI request. Corresponding custom icon is resumed.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SetAppIcon/comSetApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  syncFileName = "icon.png"
}
local requestUiParams = {
  syncFileName = {
    imageType = "DYNAMIC",
    value = common.getPathToFileInStorage(requestParams.syncFileName
  }
}
local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration with iconresumed = false", common.registerApp, { 1, true, true })
runner.Step("Upload icon file1", common.putFile)
runner.Step("SetAppIcon1", common.setAppIcon, { allParams } )

runner.Step("Upload icon file2", common.putFile)
runner.Step("SetAppIcon2", common.setAppIcon, { allParams } )

runner.Step("App unregistration", common.unregisterAppInterface, { 1 })
runner.Step("App registration with iconresumed = true", common.registerApp, { 1, true, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)