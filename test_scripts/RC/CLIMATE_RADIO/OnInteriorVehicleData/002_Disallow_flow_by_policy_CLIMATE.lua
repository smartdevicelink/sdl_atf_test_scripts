---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/7
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/Policy_Support_of_basic_RC_functionality.md
-- Item: Use Case 1: Exceptions: 5.1
--
-- Requirement summary:
-- [SDL_RC] Subscribe on RC module change notification
-- [SDL_RC] Policy support of basic RC functionality
--
-- Description:
-- In case:
-- 1) A set of module(s) is defined in policies for particular RC app
-- 2) and this RC app is subscribed to one of the module from the list
-- 3) and then SDL received OnInteriorVehicleData notification for module not in list
-- SDL must:
-- 1) Does not re-send OnInteriorVehicleData notification to the related app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mod = "CLIMATE"

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].moduleType = { mod }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions, { false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerApp)
runner.Step("PTU", commonRC.policyTableUpdate, { PTUfunc })
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("GetInteriorVehicleData " .. mod, commonRC.subscribeToModule, { mod })
runner.Step("OnInteriorVehicleData " .. mod, commonRC.isUnsubscribed, { "RADIO" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
