---------------------------------------------------------------------------------------------------
-- RPC: OnInteriorVehicleData
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

runner.Title("Test")
runner.Step("GetInteriorVehicleData " .. mod, commonRC.subscribeToModule, { mod })
runner.Step("OnInteriorVehicleData " .. mod, commonRC.isUnsubscribed, { "RADIO" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
