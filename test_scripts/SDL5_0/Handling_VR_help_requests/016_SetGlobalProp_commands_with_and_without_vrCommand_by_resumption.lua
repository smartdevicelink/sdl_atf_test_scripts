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
-- 2. send SetGlobalProperties with constructed the vrHelp and helpPrompt parameters using added vrCommands
--   after each resumed command
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Handling_VR_help_requests/commonVRhelp')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

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

local uiCommandArray = { { cmdID = commandWithVr.cmdID }, { cmdID = commandWithoutVr.cmdID } }

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
  :Times(2)
end

local function resumptionDataAddCommands()
  EXPECT_HMICALL("VR.AddCommand")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    for _, value in pairs(common.commandArray) do
      if data.params.cmdID == value.cmdID then
        local vrCommandCompareResult = commonFunctions:is_table_equal(data.params.vrCommands, value.vrCommand)
        local Msg = ""
        if vrCommandCompareResult == false then
          Msg = "vrCommands in received VR.AddCommand are not match to expected result.\n" ..
          "Actual result:" .. common.tableToString(data.params.vrCommands) .. "\n" ..
          "Expected result:" .. common.tableToString(value.vrCommand) .."\n"
        end
        return vrCommandCompareResult, Msg
      end
    end
    return true
  end)
  :Times(#common.commandArray)
  EXPECT_HMICALL("TTS.SetGlobalProperties")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_, data)
    local expectedHelpPrompt = common.vrHelpPrompt(common.commandArray)
    local vrCommandCompareResult = commonFunctions:is_table_equal(data.params.helpPrompt, expectedHelpPrompt)
    local Msg = ""
    if vrCommandCompareResult == false then
      Msg = "helpPrompt in received TTS.SetGlobalProperties is not match to expected result.\n" ..
      "Actual result:" .. common.tableToString(data.params.helpPrompt) .. "\n" ..
      "Expected result:" .. common.tableToString(expectedHelpPrompt) .."\n"
    end
    return vrCommandCompareResult, Msg
  end)

  EXPECT_HMICALL("UI.AddCommand")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    for k, value in pairs(uiCommandArray) do
      if data.params.cmdID == value.cmdID then
        return true
      elseif data.params.cmdID ~= value.cmdID and k == #uiCommandArray then
        return false, "Received cmdID in UI.AddCommand was not added previously before resumption"
      end
    end
  end)
  :Times(#uiCommandArray)
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_, data)
    local expectedVrHelp = common.vrHelp(common.commandArray)
    local vrCommandCompareResult = commonFunctions:is_table_equal(data.params.vrHelp, expectedVrHelp)
    local Msg = ""
    if vrCommandCompareResult == false then
      Msg = "vrHelp in received TTS.SetGlobalProperties is not match to expected result.\n" ..
      "Actual result:" .. common.tableToString(data.params.vrHelp) .. "\n" ..
      "Expected result:" .. common.tableToString(expectedVrHelp) .."\n"
    end
    return vrCommandCompareResult, Msg
  end)
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
runner.Step("AddCommand with vr command", common.addCommandWithSetGP, {nil, commandWithVr })
runner.Step("AddCommand without vr command", common.addCommandWithoutSetGP, {nil, commandWithoutVr })
runner.Step("App reconnect", common.reconnect)
runner.Step("App resumption", common.registrationWithResumption,
  { 1, resumptionLevelLimited, resumptionDataAddCommands })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
