---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC functionality is allowed on HMI
-- 2) RC app1 is registered
-- 3) Non-RC app2 is registered
-- 4) RC functionality is disallowed on HMI
-- SDL must:
-- 1) SDL sends an OnRCStatus notification to the HMI (allocatedModules=[], freeModules=[x,y,z], due to resource freed)
-- 2) SDL sends OnRCStatus notifications to the already registered RC apps (allowed=false, allocatedModules=[], freeModules=[])
-- 3) SDL does not send OnRCStatus notifications to the already registered non-RC apps
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function disableRCFromHMI()
  common.getHMIConnection():SendNotification("RC.OnRemoteControlSettings", { allowed = false })
  common.getMobileSession(1):ExpectNotification("OnRCStatus",
  { allowed = false, freeModules = {}, allocatedModules = {} })
  local pModuleStatusHMI = {
    freeModules = common.getModulesAllocationByApp(1).freeModules,
    allocatedModules = { }
  }
  common.validateOnRCStatusForHMI(1, pModuleStatusHMI)
  common.getMobileSession(2):ExpectNotification("OnRCStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RC app1 registration", common.registerRCApplication, { 1 })
runner.Step("Non-RC app2 registration", common.registerNonRCApp, { 2 })

runner.Title("Test")
runner.Step("RC functionality is disallowed from HMI", disableRCFromHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
