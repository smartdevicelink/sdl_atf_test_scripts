---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0115-close-application.md
-- Description:
-- In case:
-- 1) Application registered, but not activated (HMI-level is NONE)
-- 2) Mobile sends CloseApplication request to SDL
-- SDL does:
-- 1) not send ActivateApp(NONE) request to HMI
-- 2) not send OnHMIStatus(NONE) notification to mobile
-- 3) send CloseApplication response to mobile with parameters "success" = false, "resultCode" = IGNORED
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/CloseApplicationRPC/commonCloseAppRPC')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variable ]]
local errorCode = "IGNORED"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 registration", common.registerApp)

runner.Title("Test")
runner.Step("Close Application for NOT activated App", common.closeApplicationRPCUnsucces, { errorCode })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
