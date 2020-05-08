---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0122-New_rules_for_providing_VRHelpItems_VRHelpTitle.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. Mobile application sets 30 command one by one
-- 2. Mobile application sets 31 command
-- SDL does:
-- 1. send SetGlobalProperties with full list of command values for vrHelp and helpPrompt parameters after each added command
-- 2. not send SetGlobalProperties after added 31 command
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for i = 1, 30 do
  runner.Step("SetGlobalProperties from SDL after added command" ..i, common.addCommandWithSetGP, { i })
end
runner.Step("Absence SetGlobalProperties from SDL after adding 31 command", common.addCommandWithoutSetGP, { 31 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
