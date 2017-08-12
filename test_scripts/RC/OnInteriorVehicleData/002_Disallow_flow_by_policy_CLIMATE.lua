---------------------------------------------------------------------------------------------------
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

--[[ Local Variables ]]
local mod = "CLIMATE"

local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = { mod }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")
runner.Step("GetInteriorVehicleData " .. mod, commonRC.subscribeToModule, { mod })
runner.Step("OnInteriorVehicleData " .. mod, commonRC.isUnsubscribed, { "RADIO" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
