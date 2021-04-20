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
-- 2. Mobile application sets SetGlobalProperties with only custom helpPrompt
-- 3. Mobile application adds  Command4
-- 4. SDL sends SetGlobalProperties  with updated value for the vrHelp parameter using added vrCommands
-- 6. Mobile application sets SetGlobalProperties with only custom vrHelp
-- 7. Mobile application adds Command5
-- SDL does:
-- 1. not send SetGlobalProperties  with updated values for the vrHelp and helpPrompt
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local SetGPParamsWithHelpPromptOnly = common.cloneTable(common.customSetGPParams())
SetGPParamsWithHelpPromptOnly.requestParams.vrHelpTitle = nil
SetGPParamsWithHelpPromptOnly.requestParams.vrHelp = nil

local SetGPParamsWithVrHelpOnly = common.cloneTable(common.customSetGPParams())
SetGPParamsWithVrHelpOnly.requestParams.helpPrompt = nil

--[[ Local Functions ]]
local function SetGlobalPropertiesFromSDLbyAddingCommand()
  common.addCommand(common.getAddCommandParams(4))
  local params = common.getGPParams()
  local hmiConnection = common.getHMIConnection()
  EXPECT_HMICALL("UI.SetGlobalProperties", params.requestUiParams)
  :Do(function(_,data)
    hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_HMICALL("TTS.SetGlobalProperties")
  :Times(0)
end

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
runner.Step("Custom SetGlobalProperties with helpPrompt only from mobile application", common.setGlobalProperties,
  { SetGPParamsWithHelpPromptOnly })
runner.Step("SetGlobalProperties with updated value for vrHelp after added command ",
  SetGlobalPropertiesFromSDLbyAddingCommand)
runner.Step("Custom SetGlobalProperties with vrHrelp only from mobile application", common.setGlobalProperties,
  { SetGPParamsWithVrHelpOnly })
runner.Step("Absence SetGlobalProperties after added command", common.addCommandWithoutSetGP, { 5 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
