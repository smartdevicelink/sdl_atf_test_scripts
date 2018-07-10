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
-- 2. Mobile app deletes Command3 and HMI responds with resultCode = REJECTED, as result command is not deleted
-- 3. 10 seconds timer is expired
-- SDL does:
-- send SetGlobalProperties  with constructed the vrHelp and helpPrompt parameters using added vrCommands.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local params = {
    cmdID = 3
  }

--[[ Local Functions ]]
local function rejectedDeleteCommand(pParams)
  local mobSession = common.getMobileSession()
  local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("DeleteCommand", pParams)
  EXPECT_HMICALL("UI.DeleteCommand")
  :Do(function(_,data)
    hmiConnection:SendError(data.id, data.method, "REJECTED", "Request rejected")
  end)
  local requestVrParams = {
    cmdID = pParams.cmdID,
    type = "Command",
    appID = common.getHMIAppId()
  }
  EXPECT_HMICALL("VR.DeleteCommand", requestVrParams)
  :Do(function(_,data)
    hmiConnection:SendError(data.id, data.method, "REJECTED", "Request rejected")
  end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
for i = 1,3 do
  runner.Step("AddCommand" .. i, common.addCommand, { common.getAddCommandParams(i) })
end

runner.Title("Test")
runner.Step("Rejected deleting Command3", rejectedDeleteCommand, { params })
runner.Step("SetGlobalProperties with constructed the vrHelp and helpPrompt", common.setGlobalPropertiesFromSDL,
	{ true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
