---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC app1 is registered
-- 2) RC app2 is registered
-- 3) Mobile applications allocate module via ButtonPress one by one
-- SDL must:
-- 1) Send OnRCStatus notification to RC applications by module allocation via ButtonPress
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function buttonPress(pModuleType)
  common.setModuleStatus(pModuleType)
  common.rpcAllowed(pModuleType, 1, "ButtonPress")
  common.validateOnRCStatus({ 1, 2 })
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
  runner.Step("ButtonPress " .. mod, buttonPress, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
