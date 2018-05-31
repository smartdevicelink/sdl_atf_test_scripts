---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC application is registered
-- 2) Mobile application subscribes to module via GetInteriorVehicleData
-- SDL must:
-- 1) Not send OnRCStatus notification to RC application by module subscribing
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function subscribeToModuleWOOnRCStatus(pModuleType)
  common.subscribeToModule(pModuleType)
  common.getMobileSession():ExpectNotification("OnRCStatus")
  :Times(0)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application", common.registerRCApplication)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, mod in pairs(common.getModules()) do
	runner.Step("GetInteriorVehicleData " .. mod, subscribeToModuleWOOnRCStatus, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
