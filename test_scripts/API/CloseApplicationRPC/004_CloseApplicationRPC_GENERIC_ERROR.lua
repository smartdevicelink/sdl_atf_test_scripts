---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0115-close-application.md
-- Description:
-- In case:
-- 1) Application is registered
-- 2) App activated (HMI level FULL)
-- 3) Mobile sends CloseApplication request to SDL
-- 4) SDL sends ActivateApp request with HMI level NONE to HMI
-- 5) HMI doesn't sends ActivateApp response to SDL (timeout expired)
-- SDL does:
-- 1) not send OnHMIStatus(NONE) notification to mobile
-- 2) send CloseApplication response to mobile with parameters "success" = false, "resultCode" = GENERIC_ERROR
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/CloseApplicationRPC/commonCloseAppRPC')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variable ]]
local errorCode = "GENERIC_ERROR"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 registration", common.registerApp, { 1 })
runner.Step("App_2 registration", common.registerAppWOPTU, { 2 })
runner.Step("App_1 activate", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("Close Application for App_1 in FULL level",
  common.closeApplicationRPCwithoutHMIResponse, { errorCode })
runner.Step("Set HMI Level to Limited", common.hmiLeveltoLimited)
runner.Step("Close Application for App_1 in LIMITED level",
  common.closeApplicationRPCwithoutHMIResponse, { errorCode })
runner.Step("Set App_1 to HMI Level in BACKGROUND", common.activateApp, { 2 })
runner.Step("Close Application for App_1 in BACKGROUND level",
  common.closeApplicationRPCwithoutHMIResponse, { errorCode })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
