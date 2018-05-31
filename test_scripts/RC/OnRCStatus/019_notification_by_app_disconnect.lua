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
-- 3) App1 is disconnected
-- SDL must:
-- 1) Send OnRCStatus notification to registered app2 and to the HMI by app1 unexpected disconnect
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

local function closeSession()
	local pModuleStatus = common.setModuleStatusByDeallocation(freeModules, allocatedModules, "CLIMATE", 1)
	common.closeSession(1)
  common.validateOnRCStatusForApp(2, pModuleStatus)
  common.validateOnRCStatusForHMI(1, { pModuleStatus })
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
		{ appID = common.getHMIAppId(), unexpectedDisconnect = true })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application 1", common.registerRCApplication, { 1 })
runner.Step("Activate App 1", common.activateApp, { 1 })
runner.Step("Register RC application 2", common.registerRCApplication, { 2 })
runner.Step("Allocation of module CLIMATE", alocateModule, { "CLIMATE" })

runner.Title("Test")
runner.Step("OnRCStatus by application disconnect", closeSession)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
