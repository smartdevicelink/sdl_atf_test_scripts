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
-- 2) App1 set custom icon via putfile and SetAppIcon requests and is re-registered with resuming custom icon( "iconResumed" = true).
-- 3) Mobile App2 registered.
-- SDL does:
-- 1) Register App1 successfully registered and sets its app icon,
-- respond to RAI with result code "SUCCESS", "iconResumed" = true
-- 2) Register an App 2 with default icon, "iconResumed" = false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SetAppIcon/commonIconResumed')

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
runner.Step("App1 registration with iconResumed = false", common.registerAppWOPTU, { 1, false })
runner.Step("Upload icon file", common.putFile)
runner.Step("SetAppIcon", common.setAppIcon, { allParams } )
runner.Step("App1 unregistration", common.unregisterAppInterface, { 1 })
runner.Step("App1 registration with iconResumed = true", common.registerAppWOPTU, { 1, true, true })
runner.Step("App2 registration with iconResumed = false", common.registerAppWOPTU, { 2, false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
