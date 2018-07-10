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
-- 2. Perform reopening session
-- SDL does:
-- 1. resume HMI level and added before reconnection AddCommands
-- 2. send SetGlobalProperties  with constructed the vrHelp and helpPrompt parameters using added vrCommand.
--   when timer times out after resuming HMI level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local commandWithoutVr = {
  cmdID = 2,
  menuParams = {
    menuName = "CommandWithoutVr"
  }
}
local commandWithtVr = {
  cmdID = 1,
  vrCommands = { "vrCommand"},
  menuParams = {
    menuName = "commandWithtVr"
  }
}

--[[ Local Functions ]]
local function resumptionLevelLimited()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnResumeAudioSource",
    { appID =  common.getHMIAppId() })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
  { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
  { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  :Do(function(exp)
    if exp.occurences == 2 then
      common.timeActivation = timestamp()
    end
  end)
  :Times(2)
end

local function deactivateAppToLimited()
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", {appID = common.getHMIAppId()})
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Pin OnHashChange", common.pinOnHashChange)
runner.Step("App activation", common.activateApp)
runner.Step("Bring app to LIMITED HMI level", deactivateAppToLimited)

runner.Title("Test")
runner.Step("AddCommand with vr command", common.addCommand, { commandWithtVr })
runner.Step("AddCommand without vr command", common.addCommand, { commandWithoutVr })
runner.Title("Test")
runner.Step("App reconnect", common.reconnect)
runner.Step("App resumption", common.registrationWithResumption,
  { 1, resumptionLevelLimited, common.resumptionDataAddCommands })
runner.Step("SetGlobalProperties with constructed the vrHelp and helpPrompt", common.setGlobalPropertiesFromSDL,
	{ true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
