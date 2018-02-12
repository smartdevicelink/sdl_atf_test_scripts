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
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mod = "LIGHT"

local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = common.getRCAppConfig()
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = { mod }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu_n, { ptu_update_func })
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("GetInteriorVehicleData " .. mod, common.subscribeToModule, { mod })
runner.Step("OnInteriorVehicleData " .. mod, common.isUnsubscribed, { "RADIO" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
