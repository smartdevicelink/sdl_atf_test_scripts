---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData Requirement
--
-- Description:
-- In case:
-- 1) RC app sends valid and allowed by policies GetInteriorVehicleData request
-- 2) and SDL received response with successful result code and current module data from HMI
-- SDL must:
-- 1) Transfer GetInteriorVehicleData response with provided from HMI current module data for allowed module and control items
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
