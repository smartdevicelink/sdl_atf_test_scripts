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
-- 2. Mobile application sets SetGlobalProperties with custom helpPrompt and vrHelp
-- 3. 10 seconds timer is expired and SDL send SetGlobalProperties  with constructed the vrHelp and helpPrompt parameters using added vrCommands
-- 4. Mobile application adds Command4 command
-- 5.SDL sends SetGlobalProperties with updated list of commands
-- 6.Mobile application sets SetGlobalProperties with custom helpPrompt and vrHelp
-- 7.Mobile application adds Command5 command
-- SDL does:
-- not send SetGlobalProperties with updated values for the vrHelp and helpPrompt parameters
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
runner.Step("App activation", common.activateApp)
for i = 1,3 do
  runner.Step("AddCommand" .. i, common.addCommand, { common.addCommandParams(i) })
end
runner.Step("SetGlobalProperties with constructed the vrHelp and helpPrompt", common.setGlobalPropertiesFromSDL,
  { true })

runner.Title("Test")
runner.Step("SetGlobalProperties from SDL with updated values after added command4", common.addCommandWithSetGP,
  { 4 })
runner.Step("Custom SetGlobalProperties from mobile application", common.setGlobalProperties,
  { common.customSetGPParams() })
runner.Step("Absence of SetGlobalProperties request from SDL after added command5", common.addCommandWithoutSetGP,
  { 5 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
