---------------------------------------------------------------------------------------------------
-- RPC: GetInteriorVehicleData
-- Script: 001
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("GetInteriorVehicleData " .. mod, commonRC.subscribeToModule, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
