---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/9
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/button_press_emulation.md
-- Item: Use Case 1: Exceptions: 1.2
--
-- Requirement summary:
-- [SDL_RC] Button press event emulation
-- [SDL_RC] Policy support of basic RC functionality
--
-- Description:
-- In case:
-- 1) "moduleType" in app's assigned policies has an empty array
-- 2) and RC app sends ButtonPress request with valid parameters
-- SDL must:
-- 1) Allow this RPC to be processed
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function PTUfunc(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].moduleType = commonRC.json.EMPTY_ARRAY
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions, { false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerApp)
runner.Step("PTU", commonRC.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")

for _, mod in pairs(commonRC.modules) do
  runner.Step("ButtonPress " .. mod, commonRC.rpcAllowed, {mod, 1, "ButtonPress"})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
