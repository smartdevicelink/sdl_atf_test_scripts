---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall send OnRCStatus notifications to rc registered apps
-- by allocation module via SetInteriorVehicleData
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local freeModules = common.getAllModules()
local allocatedModules = {
	[1] = {}
}

--[[ General configuration parameters ]]
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function alocateModule(pModuleType)
	local pModuleStatus = common.setModuleStatus(freeModules, allocatedModules, pModuleType)
	common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
	common.validateOnRCStatusForApp(1, pModuleStatus)
	common.validateOnRCStatusForHMI(1, { pModuleStatus })
	common.getMobileSession(2):ExpectNotification("OnRCStatus")
	:Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application 1", common.registerRCApplication)
runner.Step("Activate App 1", common.activateApp)
runner.Step("Register non-RC application 2", common.rai_n, { 2 })

runner.Title("Test")
for _, mod in pairs(common.getModules()) do
	runner.Step("Allocation of module " .. mod, alocateModule, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
