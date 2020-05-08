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
-- 2. Mobile application sets SetGlobalProperties with custom helpPrompt and vrHelp after resumption
-- 3. Perform session reconnect
-- SDL does:
-- 1. resume custom SetGlobalProperties
-- 2. not send SetGlobalProperties with constructed the vrHelp and helpPrompt parameters after each resumed command
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Handling_VR_help_requests/commonVRhelp')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local SetGPParams = common.customSetGPParams()

--[[ Local Functions ]]
local function resumptionData()
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
  EXPECT_HMICALL("UI.AddCommand")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    for k, value in pairs(common.commandArray) do
      if data.params.cmdID == value.cmdID then
        return true
      elseif data.params.cmdID ~= value.cmdID and k == #common.commandArray then
        return false, "Received cmdID in UI.AddCommand was not added previously before resumption"
      end
    end
  end)
  :Times(#common.commandArray)
  local hmiConnection = common.getHMIConnection()
  EXPECT_HMICALL("UI.SetGlobalProperties", SetGPParams.requestUiParams)
  :Do(function(_,data)
    hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_HMICALL("TTS.SetGlobalProperties", SetGPParams.requestTtsParams)
  :Do(function(_,data)
    hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
end

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
runner.Step("Custom SetGlobalProperties from mobile application", common.setGlobalProperties,
  { common.customSetGPParams() })

runner.Title("Test")
runner.Step("App reconnect", common.reconnect)
runner.Step("App resumption", common.registrationWithResumption,
  { 1, common.resumptionLevelFull, resumptionData })
runner.Step("Absence of SetGlobalProperties request from SDL", common.setGlobalPropertiesDoesNotExpect)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
