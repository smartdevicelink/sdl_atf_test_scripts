---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0122-New_rules_for_providing_VRHelpItems_VRHelpTitle.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. Mobile application sets 28 command one by one
-- 2. Perform reconnect
-- 3. SDL resumes commands
-- 4. Mobile application sets 1 command in one request (29) with 2 synonyms
-- 5. Mobile application sets 1 command in one request (30)
-- 6. Mobile application sets 1 command in one request (31)
-- SDL does:
-- 1. send SetGlobalProperties with full list of command values for vrHelp and helpPrompt parameters for 28 VR commands
-- 4. send SetGlobalProperties with constructed the vrHelp and helpPrompt parameters using 1st synonym from list
-- 5. send SetGlobalProperties with constructed the vrHelp and helpPrompt parameters
-- 6. not send SetGlobalProperties after added 31 command
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local AddCommandParams = common.getAddCommandParams(29)
AddCommandParams.vrCommands = { "Command_30_1", "Command_30_2" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Pin OnHashChange", common.pinOnHashChange)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for i = 1, 28 do
  runner.Step("SetGlobalProperties from SDL after added command " .. i, common.addCommandWithSetGP, { i })
end
runner.Step("App reconnect", common.reconnect)
runner.Step("App resumption", common.registrationWithResumption,
  { 1, common.resumptionLevelFull, common.resumptionDataAddCommands })
runner.Step("SetGlobalProperties after AddCommand with several vrCommand", common.addCommandWithSetGP,
  { nil, AddCommandParams })
runner.Step("SetGlobalProperties from SDL after added command 30", common.addCommandWithSetGP, { 30 })
runner.Step("Absence SetGlobalProperties from SDL after adding 31 VR command", common.addCommandWithoutSetGP, { 31 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
