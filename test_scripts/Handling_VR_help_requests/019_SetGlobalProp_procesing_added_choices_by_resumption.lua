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
-- 2. vrCommands Choice1, Choice2 are added via CreateInterationChoiceSet
-- 3. Perform session reconnect
-- SDL does:
-- send SetGlobalProperties  with constructed the vrHelp and helpPrompt parameters using added vrCommands via AddCommand
-- requests(with type "Command") after resumption in 10 seconds after FULL hmi level
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Handling_VR_help_requests/commonVRhelp')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local requestParams = {
  interactionChoiceSetID = 1001,
  choiceSet = {
    {
      choiceID = 1001,
      menuName ="Choice1001",
      vrCommands = {
	    "Choice1001_1", "Choice1001_2"
      }
    }
  }
}

local responseVrParams = {
  cmdID = requestParams.interactionChoiceSetID,
  type = "Choice",
  vrCommands = requestParams.vrCommands
}

local commandArrayResumption = {  }

-- [[ Local Functions ]]
local function createInteractionChoiceSetWithoutSetGP()
  local mobSession = common.getMobileSession(1)
  local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("CreateInteractionChoiceSet", requestParams)
    EXPECT_HMICALL("VR.AddCommand", responseVrParams)
    :Do(function(_,data)
      commandArrayResumption = common.cloneTable(common.commandArray)
      table.insert(commandArrayResumption, { cmdID = data.params.cmdID, vrCommand = data.params.vrCommands})
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

local function resumptionDataAddCommands()
  EXPECT_HMICALL("VR.AddCommand")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
    for _, value in pairs(commandArrayResumption) do
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
  :Times(#commandArrayResumption)
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
  runner.Step("AddCommand" .. i, common.addCommand, { common.getAddCommandParams(i) })
end
runner.Step("CreateInteractionChoiceSet", createInteractionChoiceSetWithoutSetGP)
runner.Step("App reconnect", common.reconnect)
runner.Step("App resumption", common.registrationWithResumption,
  { 1, common.resumptionLevelFull, resumptionDataAddCommands })
runner.Step("SetGlobalProperties with constructed the vrHelp and helpPrompt", common.setGlobalPropertiesFromSDL,
	{ true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
