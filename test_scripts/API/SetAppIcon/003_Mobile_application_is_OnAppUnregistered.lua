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
-- 3) Mobile application is OnAppUnregistered.
-- 4) Mobile app is re-registered.
-- SDL does:
-- 1) 1) SDL respons with result code "SUCCESS" and "iconResumed" = true for RAI request.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SetAppIcon/comSetApp')
Test = require('user_modules/connecttest_OnAppUnregistered')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  syncFileName = "icon.png"
}
local requestUiParams = {
  syncFileName = {
    imageType = "DYNAMIC",
    value = common.getPathToFileInStorage(requestParams.syncFileName)
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
runner.Step("App registration with iconresumed = true", common.registerApp, { 1, true })
runner.Step("Upload icon file", common.putFile)
runner.Step("SetAppIcon", common.setAppIcon, { allParams } )
runner.Step("App OnAppUnregistered", common.unregisterAppInterface, { 1 })
runner.Step("App registration with iconresumed = true", common.registerApp, { 1, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
