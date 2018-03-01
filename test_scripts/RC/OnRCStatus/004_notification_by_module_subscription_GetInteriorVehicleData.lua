---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall not send OnRCStatus notifications to rc registered app
-- by allocation module via GetInteriorVehicleData
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonOnRCStatus = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function SubscribeToModuleWOOnRCStatus(pModuleType)
	commonOnRCStatus.SubscribeToModuleWOOnRCStatus(pModuleType)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonOnRCStatus.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonOnRCStatus.start)
runner.Step("RAI, PTU", commonOnRCStatus.RegisterRCapplication)
runner.Step("Activate App", commonOnRCStatus.ActivateApp)

runner.Title("Test")
for _, mod in pairs(commonOnRCStatus.modules) do
	runner.Step("GetInteriorVehicleData " .. mod, SubscribeToModuleWOOnRCStatus, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonOnRCStatus.postconditions)
