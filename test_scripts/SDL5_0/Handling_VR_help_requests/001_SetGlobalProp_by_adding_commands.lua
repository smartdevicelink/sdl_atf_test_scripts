---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0122-New_rules_for_providing_VRHelpItems_VRHelpTitle.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. Command1, Command2, Command3 commands with vrCommands are added
-- SDL does:
-- send SetGlobalProperties  with constructed the vrHelp and helpPrompt parameters using added vrCommands
-- after receiving each command
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
for i = 1,3 do
  runner.Step("SetGlobalProperties after AddCommand" .. i, common.addCommandWithSetGP, { i })
end
runner.Step("Absence of SetGlobalProperties request from SDL", common.setGlobalPropertiesDoesNotExpect)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
