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
-- 2. Mobile application sends SetGlobalProperties with invalid data( e.g. invalid type )
-- 3. SDL responds with resultCode INVALID_DATA to mobile application
-- 4. Mobile application adds Command4
-- SDL does:
-- send SetGlobalProperties  with constructed the vrHelp and helpPrompt parameters using added vrCommands.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Handling_VR_help_requests/commonVRhelp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function invalidSetGlobalProperties()
  local mobSession = common.getMobileSession()
  local Params = common.customSetGPParams()
  Params.requestParams.vrHelpTitle = 1234
  local cid = mobSession:SendRPC("SetGlobalProperties", Params.requestParams)
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_HMICALL("TTS.SetGlobalProperties")
  :Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA"})
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
runner.Step("Invalid custom SetGlobalProperties", invalidSetGlobalProperties)
runner.Step("SetGlobalProperties after AddCommand 4", common.addCommandWithSetGP, { 4 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
