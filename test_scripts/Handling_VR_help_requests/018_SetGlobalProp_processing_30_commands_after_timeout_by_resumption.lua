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
-- 2. Perform reopening session
-- SDL does:
-- 1. send SetGlobalProperties  with full list of command values  for vrHelp and helpPrompt parameters after each added
--   command after resumption in 10 seconds after FULL hmi level
-- 2. send SetGlobalProperties  with full list of command values for vrHelp and helpPrompt parameters after each added command
-- 3. not send SetGlobalProperties after added 31 command
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Pin OnHashChange", common.pinOnHashChange)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for i = 1,3 do
  runner.Step("AddCommand" .. i, common.addCommand, { common.getAddCommandParams(i) })
end
runner.Step("App reconnect", common.reconnect)
runner.Step("App resumption", common.registrationWithResumption,
  { 1, common.resumptionLevelFull, common.resumptionDataAddCommands })
runner.Step("SetGlobalProperties with constructed the vrHelp and helpPrompt", common.setGlobalPropertiesFromSDL,
	{ true })
for i = 4, 33 do
	runner.Step("SetGlobalProperties from SDL after added command" ..i, common.addCommandWithSetGP, { i })
end
runner.Step("Absence SetGlobalProperties from SDL after adding 34 command", common.addCommandWithoutSetGP, { 34 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
