---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0116-open-menu.md
-- Description:
-- In case:
-- 1) Mobile application is set to FULL HMI level and System Context MAIN
-- 2) Mobile application is added SubMenu with menuID  = 5
-- 3) Mobile sends ShowAppMenu request with menuID = 10 parameter to SDL
-- SDL does:
-- 1) not send ShowAppMenu request to HMI
-- 2) send ShowAppMenu response to mobile with parameters "success" = false, resultCode = INVALID_ID
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ShowAppMenu/commonShowAppMenu')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "PROJECTION" }

--[[ Local Variables ]]
local resultCode = "INVALID_ID"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)

runner.Title("Test")
runner.Step("Add menu", common.addSubMenu, { 5 })
runner.Step("Send show app menu", common.showAppMenuUnsuccess, { 10, resultCode })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
