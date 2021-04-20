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
-- 2. Mobile application sends valid SetGlobalProperties and HMI rejected request
-- 3. SDL responds with resultCode REJECTED to mobile application
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
local function rejectedSetGlobalProperties()
  local mobSession = common.getMobileSession()
  local hmiConnection = common.getHMIConnection()
  local Params = common.customSetGPParams()
  local cid = mobSession:SendRPC("SetGlobalProperties", Params.requestParams)
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Do(function(_,data)
    hmiConnection:SendError(data.id, data.method, "REJECTED", " UI is rejected ")
  end)
  EXPECT_HMICALL("TTS.SetGlobalProperties")
  :Do(function(_,data)
    hmiConnection:SendError(data.id, data.method, "REJECTED", " TTS is rejected ")
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
  runner.Step("AddCommand" .. i, common.addCommandWithSetGP, { i })
end

runner.Title("Test")
runner.Step("Rejected custom SetGlobalProperties", rejectedSetGlobalProperties)
runner.Step("SetGlobalProperties after AddCommand 4", common.addCommandWithSetGP, { 4 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
