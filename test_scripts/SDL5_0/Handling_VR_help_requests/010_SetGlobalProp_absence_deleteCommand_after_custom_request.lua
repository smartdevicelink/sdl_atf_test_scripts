---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0122-New_rules_for_providing_VRHelpItems_VRHelpTitle.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. Mobile application deletes Command1 command
-- 2. SDL sends SetGlobalProperties with updated list of command
-- 3. Mobile application sets SetGlobalProperties with custom helpPrompt and vrHelp
-- 4. Mobile application deletes  Command2
-- SDL does:
-- not send SetGlobalProperties with updated values for the vrHelp and helpPrompt parameters
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
for i = 1,3 do
  runner.Step("AddCommand" .. i, common.addCommandWithSetGP, { i })
end

runner.Title("Test")
runner.Step("SetGlobalProperties from SDL with updated values after deleting command1", common.deleteCommandWithSetGP,
  { 1 })
runner.Step("Custom SetGlobalProperties from mobile application", common.setGlobalProperties,
  { common.customSetGPParams() })
runner.Step("Absence of SetGlobalProperties request from SDL after deleting command2", common.deleteCommandWithoutSetGP,
  { 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
