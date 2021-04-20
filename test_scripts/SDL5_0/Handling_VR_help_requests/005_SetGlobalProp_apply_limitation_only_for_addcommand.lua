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
-- 2. Mobile application set/delete commands
-- SDL does:
-- send SetGlobalProperties with 30 items only in case if first 30 items in list are updated
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
runner.Title("Add 30 commands")
for i = 1, 30 do
  runner.Step("SetGlobalProperties from SDL after added command " ..i, common.addCommandWithSetGP, { i })
end
runner.Title("Change list of commands")
runner.Step("No SetGlobalProperties from SDL after added command 31", common.addCommandWithoutSetGP, { 31 })
runner.Step("No SetGlobalProperties from SDL after deleted command 31", common.deleteCommandWithoutSetGP, { 31 })
runner.Step("No SetGlobalProperties from SDL after added command 32", common.addCommandWithoutSetGP, { 32 })
runner.Step("SetGlobalProperties from SDL after deleted command 1", common.deleteCommandWithSetGP, { 1 })
runner.Step("No SetGlobalProperties from SDL after added command 33", common.addCommandWithoutSetGP, { 33 })
runner.Step("SetGlobalProperties from SDL after deleted command 2", common.deleteCommandWithSetGP, { 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
