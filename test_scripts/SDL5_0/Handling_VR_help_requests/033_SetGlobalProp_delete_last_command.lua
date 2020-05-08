---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0122-New_rules_for_providing_VRHelpItems_VRHelpTitle.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. Mobile application sets 30 commands
-- 2. Mobile application sets 31st command
-- 3. Mobile application removes 31st command
-- 4. Mobile application removes 1st command
-- 5. Mobile application sets 32nd command
-- SDL does:
-- 1. send SetGlobalProperties with full list of command values for vrHelp and helpPrompt parameters for 30 VR commands
-- 2. not send SetGlobalProperties for 31st VR command
-- 3. not send SetGlobalProperties when 31st VR command is removed
-- 4. send SetGlobalProperties with full list of command values for vrHelp and helpPrompt parameters for 30 VR commands
-- when 1st VR command is removed
-- 5. send SetGlobalProperties with full list of command values for vrHelp and helpPrompt parameters for 32nd VR command
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
  runner.Step("SetGlobalProperties from SDL after added command " .. i, common.addCommandWithSetGP, { i })
end
runner.Step("No SetGlobalProperties from SDL after added command 31", common.addCommandWithoutSetGP, { 31 })
runner.Step("No SetGlobalProperties from SDL after deleted command 31", common.deleteCommandWithoutSetGP, { 31 })
runner.Step("SetGlobalProperties from SDL after deleted command 1", common.deleteCommandWithSetGP, { 1 })
runner.Step("SetGlobalProperties from SDL after added command 32", common.addCommandWithSetGP, { 32 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
