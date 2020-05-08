---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0116-open-menu.md
-- Description:
-- In case:
-- 1) Mobile application is set to FULL HMI level and System Context MAIN
-- 2) Mobile sends ShowAppMenu request to SDL
-- 3) SDL sends ShowAppMenu request to HMI
-- 4) HMI doesn't send ShowAppMenu response to SDL (timeout expired)
-- SDL does:
-- 1) send ShowAppMenu response to mobile with parameters "success" = false, resultCode = GENERIC_ERROR
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
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)

runner.Title("Test")
runner.Step("Send show app menu", common.showAppMenuHMIwithoutResponse, { nil })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
