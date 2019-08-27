---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC app1 and RC app2 are registered
-- 2) Module_1 is allocated by app1
-- 3) App2 allocates the allocated module_1 by app1
-- SDL must:
-- 1) Send OnRCStatus notifications to RC apps and to HMI by app2 tries allocate the allocated module by app1
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function alocateModuleFirstApp(pModuleType)
  common.setModuleStatus("CLIMATE")
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.validateOnRCStatus({1,2})
end

local function alocateModuleSecondApp(pModuleType)
  common.setModuleStatus("CLIMATE", 2)
  common.rpcAllowed(pModuleType, 2, "SetInteriorVehicleData")
  common.validateOnRCStatus({1, 2})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application 1", common.registerRCApplication, { 1 })
runner.Step("Register RC application 2", common.registerRCApplication, { 2 })
runner.Step("Activate App 1", common.activateApp)

runner.Title("Test")
runner.Step("App1 allocates module CLIMATE", alocateModuleFirstApp, { "CLIMATE"})
runner.Step("Activate App 2", common.activateApp, { 2 })
runner.Step("App2 allocates module CLIMATE", alocateModuleSecondApp, { "CLIMATE"})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
