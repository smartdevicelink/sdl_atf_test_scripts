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
-- 2. Mobile application sets SetGlobalProperties without helpPrompt and vrHelp
-- 3. 10 seconds timer is expired
-- SDL does:
-- send SetGlobalProperties with constructed the vrHelp and helpPrompt parameters using added vrCommand.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Handling_VR_help_requests/commonVRhelp')

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
runner.Step("App activation", common.activateApp)
for i = 1,3 do
  runner.Step("AddCommand" .. i, common.addCommand, { common.getAddCommandParams(i) })
end

runner.Title("Test")
runner.Step("Custom SetGlobalProperties from mobile application without helpPrompt and vrHelp",
  common.setGlobalProperties, { setGPParams })
runner.Step("SetGlobalProperties request from SDL with constructed the vrHelp and helpPrompt",
  common.setGlobalPropertiesFromSDL, { true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
