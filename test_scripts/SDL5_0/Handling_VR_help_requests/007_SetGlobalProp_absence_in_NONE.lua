---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0122-New_rules_for_providing_VRHelpItems_VRHelpTitle.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. App is registered and set in NONE HMI level.
-- 2. PT is updated with "NONE" for AddCommand RPC
-- 3. Command1, Command2, Command3 commands with vrCommands are added
-- SDL does:
-- send SetGlobalProperties  with constructed the vrHelp and helpPrompt parameters using added vrCommands
-- after receiving each command
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function ptuFunc(tbl)
	tbl.policy_table.functional_groupings["Base-4"].rpcs.AddCommand.hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration", common.registerApp)
runner.Step("PTU with NONE hmi level for AddCommand", common.policyTableUpdate, { ptuFunc })

runner.Title("Test")
for i = 1,3 do
  runner.Step("SetGlobalProperties after AddCommand" .. i, common.addCommandWithSetGP, { i })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
