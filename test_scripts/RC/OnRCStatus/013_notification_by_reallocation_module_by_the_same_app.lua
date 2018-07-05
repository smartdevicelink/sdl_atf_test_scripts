---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall not send OnRCStatus notifications to rc registered app and HMI
-- in case application tries allocate already allocated module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function alocateModuleWithoutNot(pModuleType)
	common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
	common.getMobileSession(1):ExpectNotification("OnRCStatus")
	:Times(0)
	EXPECT_HMINOTIFICATION("RC.OnRCStatus")
	:Times(0)
end

local function alocateModule(pModuleType)
	local pModuleStatus = common.setModuleStatus(common.getAllModules(), {{}}, pModuleType)
	common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
	common.validateOnRCStatusForApp(1, pModuleStatus)
	common.validateOnRCStatusForHMI(1, { pModuleStatus })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application", common.registerRCApplication)
runner.Step("Activate App", common.activateApp)
runner.Step("Allocate module CLIMATE", alocateModule, { "CLIMATE" })

runner.Title("Test")
runner.Step("App allocates module CLIMATE one more time", alocateModuleWithoutNot, { "CLIMATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
