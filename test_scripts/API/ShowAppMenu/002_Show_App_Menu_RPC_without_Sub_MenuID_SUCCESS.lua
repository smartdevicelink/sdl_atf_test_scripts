---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0116-open-menu.md
-- Description:
-- In case:
-- 1) Mobile application is set to appropriate HMI level and System Context MENU, MAIN
-- 2) Mobile sends ShowAppMenu request without menuID parameter to SDL
-- 3) SDL sends ShowAppMenu request without menuID parameter to HMI
-- 4) HMI sends ShowAppMenu response with resultCode = SUCCESS to SDL
-- SDL does:
-- 1) send ShowAppMenu response with resultCode = SUCCESS to mobile
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ShowAppMenu/commonShowAppMenu')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "PROJECTION" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)
runner.Step("Send show app menu, HMI SystemContext MAIN", common.showAppMenuSuccess, { nil })
runner.Step("Set HMI SystemContext to MENU", common.changeHMISystemContext, { "MENU" })
runner.Step("Show app menu, HMI SystemContext MENU", common.showAppMenuSuccess, { nil })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
