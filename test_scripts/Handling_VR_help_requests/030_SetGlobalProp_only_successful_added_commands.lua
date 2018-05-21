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
-- 2. Mobile app adds Command4 and HMI responds with resultCode = REJECTED, as result command is not added
-- 3. 10 seconds timer is expired
-- SDL does:
-- send SetGlobalProperties  with constructed the vrHelp and helpPrompt parameters using added vrCommands.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function rejectedAddCommand(pParams)
  local mobSession = common.getMobileSession()
  local hmiConnection = common.getHMIConnection()
  local cid = mobSession:SendRPC("AddCommand", pParams)
  EXPECT_HMICALL("UI.AddCommand")
  :Do(function(_,data)
    hmiConnection:SendError(data.id, data.method, "REJECTED", "Rejected request")
  end)
  local requestUiParams = {
    cmdID = pParams.cmdID,
    vrCommands = pParams.vrCommands,
    type = "Command",
    appID = common.getHMIAppId()
  }
  EXPECT_HMICALL("VR.AddCommand", requestUiParams)
  :Do(function(_,data)
    hmiConnection:SendError(data.id, data.method, "REJECTED", "Rejected request")
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
runner.Step("Rejected adding Command4", rejectedAddCommand, { common.getAddCommandParams(4) })
runner.Step("SetGlobalProperties with constructed the vrHelp and helpPrompt", common.setGlobalPropertiesFromSDL,
	{ true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
