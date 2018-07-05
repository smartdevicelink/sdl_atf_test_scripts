---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall send OnRCStatus notifications to rc registered apps and to HMI
-- in case HMI sends SUCCESS resultCode to RC.GetInteriorVehicleDataConsent
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local freeModules = common.getAllModules()
local allocatedModules = {
  [1] = {},
  [2] = {}
}

--[[ Local Functions ]]
local function alocateModule(pModuleType)
  local pModuleStatusAllocatedApp, pModuleStatusAnotherApp = common.setModuleStatus(freeModules, allocatedModules, pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.validateOnRCStatusForApp(1, pModuleStatusAllocatedApp)
  common.validateOnRCStatusForApp(2, pModuleStatusAnotherApp)
  common.validateOnRCStatusForHMI(2, { pModuleStatusAllocatedApp, pModuleStatusAnotherApp }, 1)
end

local function subscribeToModuleWithDriverConsent(pModuleType)
	local pModuleStatusAllocatedApp, pModuleStatusAnotherApp = common.setModuleStatus(freeModules, allocatedModules, pModuleType, 2)
	common.rpcAllowedWithConsent(pModuleType, 2, "SetInteriorVehicleData")
  common.validateOnRCStatusForApp(1, pModuleStatusAnotherApp)
  common.validateOnRCStatusForApp(2, pModuleStatusAllocatedApp)
  common.validateOnRCStatusForHMI(2, { pModuleStatusAnotherApp, pModuleStatusAllocatedApp }, 2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Set AccessMode ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Register RC application 1", common.registerRCApplication, { 1 })
runner.Step("Activate App 1", common.activateApp, { 1 })
runner.Step("Register RC application 1", common.registerRCApplication, { 2 })
runner.Step("Activate App 2", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("Allocation of module by App 1", alocateModule, { "CLIMATE" })
runner.Step("Allocation of module by App 2 with driver consent", subscribeToModuleWithDriverConsent, { "CLIMATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
