---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC applications is registered
-- 2) Mobile application allocates module via ButtonPress
-- SDL must:
-- 1) send OnRCStatus notification to RC application by module allocation via ButtonPress
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local freeModules = common.getAllModules()
local allocatedModules = {
	[1] = { }
}

--[[ Local Functions ]]
local function buttonPress(pModuleType)
	local pModuleStatus = common.setModuleStatus(freeModules, allocatedModules, pModuleType)
	common.rpcAllowed(pModuleType, 1, "ButtonPress")
	common.validateOnRCStatusForApp(1, pModuleStatus)
	common.validateOnRCStatusForHMI(1, { pModuleStatus })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application", common.registerRCApplication)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, mod in pairs(common.getModules()) do
  runner.Step("ButtonPress " .. mod, buttonPress, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
