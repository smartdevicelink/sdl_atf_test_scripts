---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall send OnRCStatus notifications to rc registered apps
-- by allocation module via SetInteriorVehicleData
-- In case:
-- 1) RC app1 is registered
-- 2) Non-RC app2 is registered
-- 3) App1 allocates module via SetInteriorVehicleData
-- SDL must:
-- 1) Send OnRCStatus notification to RC app1 only by module allocation via SetInteriorVehicleData
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function alocateModule(pModuleType)
  common.setModuleStatus(pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.validateOnRCStatus({ 1 })
  common.getMobileSession(2):ExpectNotification("OnRCStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application 1", common.registerRCApplication)
runner.Step("Activate App 1", common.activateApp)
runner.Step("Register non-RC application 2", common.registerAppWOPTU, { 2 })

runner.Title("Test")
for _, mod in pairs(common.getAllModules()) do
  runner.Step("Allocation of module " .. mod, alocateModule, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
