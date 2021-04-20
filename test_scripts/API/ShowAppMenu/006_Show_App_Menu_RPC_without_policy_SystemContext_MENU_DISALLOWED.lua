---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0116-open-menu.md
-- Description:
-- In case:
-- 1) Mobile application is set to appropriate HMI level and System Context MENU
-- 2) ShowAppMenu RPC is not allowed by policy
-- 3) Mobile sends ShowAppMenu request without menuID parameter to SDL
-- SDL does:
-- 1) not send ShowAppMenu request to HMI
-- 2) send ShowAppMenu response with resultCode = DISALLOWED to mobile
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ShowAppMenu/commonShowAppMenu')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "PROJECTION" }

--[[ Local Variables ]]
local resultCode = "DISALLOWED"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })

runner.Title("Test")
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)
runner.Step("Set HMI SystemContext to MENU" , common.changeHMISystemContext, { "MENU" })
runner.Step("Set HMI Level to Limited", common.hmiLeveltoLimited, { 1, "MENU" })
runner.Step("Send show App menu, Limited level", common.showAppMenuUnsuccess, { nil, resultCode })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
