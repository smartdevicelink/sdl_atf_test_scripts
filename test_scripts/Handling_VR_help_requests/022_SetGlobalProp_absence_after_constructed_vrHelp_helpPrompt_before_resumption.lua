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
-- 2. 10 seconds timer is expired
-- 3. send SetGlobalProperties  with constructed the vrHelp and helpPrompt parameters using added vrCommands.
-- 4. Perform session reconnect
-- SDL does:
-- 1. Resume SetGlobalProperties
-- 2. not send SetGlobalProperties with constructed the vrHelp and helpPrompt parameters using added vrCommands.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function resumptionData()
  common.resumptionDataAddCommands()
  common.setGlobalPropertiesFromSDL()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Pin OnHashChange", common.pinOnHashChange)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for i = 1,3 do
  runner.Step("AddCommand" .. i, common.addCommand, { common.addCommandParams(i) })
end
runner.Step("SetGlobalProperties with constructed the vrHelp and helpPrompt", common.setGlobalPropertiesFromSDL,
  { true })
runner.Step("Wait for resumption data saving", common.wait, { 10000 })
runner.Step("App reconnect", common.reconnect)
runner.Step("App resumption", common.registrationWithResumption,
  { 1, common.resumptionLevelFull, resumptionData })
runner.Step("Absence of SetGlobalProperties request from SDL", common.setGlobalPropertiesDoesNotExpect)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
