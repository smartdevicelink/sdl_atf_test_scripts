---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall not send OnRCStatus notifications to rc registered apps
-- by allocation module via GetInteriorVehicleData
-- In case:
-- 1) RC app1 is registered
-- 2) RC app2 is registered
-- 3) Mobile applications subscribe to module via GetInteriorVehicleData one by one
-- SDL must:
-- 1) Not send OnRCStatus notification to RC applications by module subscribing
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function subscribeToModuleWOOnRCStatus(pModuleType)
	common.subscribeToModule(pModuleType)
	common.getMobileSession(1):ExpectNotification("OnRCStatus")
	:Times(0)
	common.getMobileSession(2):ExpectNotification("OnRCStatus")
	:Times(0)
	EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application 1", common.registerRCApplication, { 1 })
runner.Step("Activate App 1", common.activateApp, { 1 })
runner.Step("Register RC application 2", common.registerRCApplication, { 2 })

runner.Title("Test")
for _, mod in pairs(common.getModules()) do
	runner.Step("GetInteriorVehicleData " .. mod, subscribeToModuleWOOnRCStatus, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
