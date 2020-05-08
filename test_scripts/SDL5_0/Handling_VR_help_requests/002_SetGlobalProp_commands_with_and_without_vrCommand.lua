---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0122-New_rules_for_providing_VRHelpItems_VRHelpTitle.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. Command1 with vrCommand and Command2 without vrCommands are added
-- SDL does:
-- send SetGlobalProperties  with constructed the vrHelp and helpPrompt parameters using added vrCommand
-- only after receiving Command1.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local commandWithoutVr = {
  cmdID = 2,
  menuParams = {
    menuName = "CommandWithoutVr"
  }
}
local commandWithVr = {
  cmdID = 1,
  vrCommands = { "vrCommand"},
  menuParams = {
    menuName = "commandWithVr"
  }
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("SetGlobalProperties after AddCommand with vr command", common.addCommandWithSetGP, { nil, commandWithVr })
runner.Step("Absence of SetGlobalProperties after AddCommand without vr command", common.addCommandWithoutSetGP, { nil, commandWithoutVr })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
