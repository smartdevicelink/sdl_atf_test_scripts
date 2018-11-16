---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0115-close-application.md
-- Description:
-- In case:
-- 1) CloseApplication request is not allowed
-- 2) App activated (HMI level FULL)
-- 3) Mobile sends CloseApplication request to SDL
-- SDL does:
-- 1) not send ActivateApp request to HMI
-- 2) not send OnHMIStatus(NONE) notification to mobile
-- 3) send CloseApplication response to mobile with parameters "success" = false, "resultCode" = DISALLOWED
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/CloseApplicationRPC/commonCloseAppRPC')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variable ]]
local errorCode = "DISALLOWED"

--[[ Local Function ]]
local function pTUpdateFunc(pTbl)
	pTbl.policy_table.functional_groupings["Base-4"].rpcs.CloseApplication = nil
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 registration", common.registerApp, { 1 })
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("App_2 registration", common.registerApp, { 2 })
runner.Step("App_1 activate", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("Close Application for App_1 in FULL level", common.closeApplicationRPCUnsucces, { errorCode })
runner.Step("Set HMI Level to Limited)", common.hmiLeveltoLimited)
runner.Step("Close Application for App_1 in LIMITED level", common.closeApplicationRPCUnsucces, { errorCode })
runner.Step("Set App_1 to HMI Level - BACKGROUND)", common.activateApp, { 2 })
runner.Step("Close Application for App_1 in BACKGROUND level", common.closeApplicationRPCUnsucces, { errorCode })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)