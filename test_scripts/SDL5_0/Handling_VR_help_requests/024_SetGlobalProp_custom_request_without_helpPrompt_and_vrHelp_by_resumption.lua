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
-- 2. Perform reconnect
-- 3. Mobile application sets SetGlobalProperties without helpPrompt and vrHelp
-- 4. Mobile application adds Command4
-- SDL does:
-- send SetGlobalProperties with constructed the vrHelp and helpPrompt parameters using added vrCommand with type=Command.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local setGPParams = { }
setGPParams.requestParams = {
  keyboardProperties = {
	keyboardLayout = "QWERTY",
	keypressMode = "SINGLE_KEYPRESS"
  }
}
setGPParams.requestUiParams = setGPParams.requestParams

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Pin OnHashChange", common.pinOnHashChange)
runner.Step("App activation", common.activateApp)
for i = 1,3 do
  runner.Step("AddCommand" .. i, common.addCommandWithSetGP, { i })
end
runner.Step("App reconnect", common.reconnect)
runner.Step("App resumption", common.registrationWithResumption,
  { 1, common.resumptionLevelFull, common.resumptionDataAddCommands })

runner.Title("Test")
runner.Step("Custom SetGlobalProperties from mobile application without helpPrompt and vrHelp",
	common.setGlobalProperties, { setGPParams })
runner.Step("SetGlobalProperties after adding AddCommand4", common.addCommandWithSetGP, { 4 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
