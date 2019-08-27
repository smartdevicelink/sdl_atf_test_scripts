---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- 1) RC app1 and app2 are registered
-- 2) AccessMode is ASK_DRIVER on HMI
-- 3) Module_1 is allocated by app1
-- 4) App2 tries to allocate module_1
-- 5) SDL requests RC.GetInteriorVehicleDataConsent and HMI sends SUCCESS resultCode to RC.GetInteriorVehicleDataConsent
-- SDL must:
-- 1) Send OnRCStatus notification to RC applications by accepting RC.GetInteriorVehicleDataConsent
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function alocateModule(pModuleType)
  common.setModuleStatus(pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.validateOnRCStatus({ 1, 2 })
end

local function subscribeToModuleWithDriverConsent(pModuleType)
  common.setModuleStatus(pModuleType, 2)
  common.rpcAllowedWithConsent(pModuleType, 2, "SetInteriorVehicleData")
  common.validateOnRCStatus({ 1, 2 })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Set AccessMode ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Register RC application 1", common.registerRCApplication, { 1 })
runner.Step("Activate App 1", common.activateApp, { 1 })
runner.Step("Register RC application 2", common.registerRCApplication, { 2 })
runner.Step("Activate App 2", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("Allocation of module by App 1", alocateModule, { "CLIMATE" })
runner.Step("Allocation of module by App 2 with driver consent", subscribeToModuleWithDriverConsent, { "CLIMATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
