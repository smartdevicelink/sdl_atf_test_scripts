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
-- 2) Mobile app is registered. Sends  PutFile and invalid SetAppIcon requests.
-- 3) Mobile App received response SetAppIcon(INVALID_DATA). Custom Icon is not set.
-- 4) App is re-registered.
-- SDL does:
-- 1) Registers an app successfully, responds to RAI with result code "SUCCESS", "iconResumed" = false.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SetAppIcon/comSetApp')

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
runner.Step("App1 registration with iconresumed = true", common.registerApp, { 1, true, true })
runner.Step("Upload icon file", common.putFile)
runner.Step("SetAppIcon", common.setAppIcon, { allParams } )

runner.Step("App2 registration with iconresumed = true", common.registerApp, { 1, true, true })
runner.Step("Upload icon file", common.putFile)
runner.Step("SetAppIcon", common.setAppIcon, { allParams } )
runner.Step("App1 unregistration", common.unregisterAppInterface, { 1 })
runner.Step("App2 unregistration", common.unregisterAppInterface, { 1 })

runner.Step("App1 registration with iconresumed = true", common.registerApp, { 1, true, true })
runner.Step("App2 registration with iconresumed = true", common.registerApp, { 1, true, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
