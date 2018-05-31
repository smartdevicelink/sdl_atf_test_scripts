---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC app1 and app2 are registered
-- 2) App1 allocates module
-- 3) App1 is unregistered
-- SDL must:
-- 1) send OnRCStatus notification to registered app2 and to the HMI by app1 unregistration with allocated module.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local allocatedModules = {
  [1] = {},
  [2] = {}
}

--[[ Local Functions ]]
local function alocateModule(pModuleType)
  local pModuleStatusAllocatedApp, pModuleStatusAnotherApp = common.setModuleStatus(common.getAllModules(), allocatedModules, pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.validateOnRCStatusForApp(1, pModuleStatusAllocatedApp)
  common.validateOnRCStatusForApp(2, pModuleStatusAnotherApp)
  common.validateOnRCStatusForHMI(2, { pModuleStatusAllocatedApp, pModuleStatusAnotherApp }, 1)
end

local function unregistration()
  local pModuleStatus = {
    freeModules = common.getModulesArray(common.getAllModules()),
    allocatedModules = { }
  }
  common.unregisterApp()
  common.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  common.validateOnRCStatusForApp(2, pModuleStatus)
  common.validateOnRCStatusForHMI(1, { pModuleStatus })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application 1", common.registerRCApplication, { 1 })
runner.Step("Register RC application 2", common.registerRCApplication, { 2 })
runner.Step("Activate App 1", common.activateApp)
runner.Step("Allocating module CLIMATE", alocateModule, { "CLIMATE" })

runner.Title("Test")
runner.Step("OnRCStatus by app unregistration", unregistration)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
