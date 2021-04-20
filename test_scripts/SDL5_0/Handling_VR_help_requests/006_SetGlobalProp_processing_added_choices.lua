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
-- SDL does:
-- send SetGlobalProperties with constructed the vrHelp and helpPrompt parameters using added vrCommands via AddCommand
-- requests(with type "Command" ).
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Handling_VR_help_requests/commonVRhelp')

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

-- [[ Local Functions ]]
local function createInteractionChoiceSetWithoutSetGP()
  local mobSession = common.getMobileSession(1)
  local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("CreateInteractionChoiceSet", requestParams)
  EXPECT_HMICALL("VR.AddCommand", responseVrParams)
  :Do(function(_,data)
    hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  common.setGlobalPropertiesDoesNotExpect()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for i = 1,3 do
  runner.Step("AddCommand" .. i, common.addCommandWithSetGP, { i })
end
runner.Step("CreateInteractionChoiceSet", createInteractionChoiceSetWithoutSetGP)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
