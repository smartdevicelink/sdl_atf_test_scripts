---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC functionality is disallowed on HMI
-- 2) RC app1 is registered
-- 3) Non-RC app2 is registered
-- 4) RC functionality is allowed on HMI
-- SDL must:
-- 1) send an OnRCStatus notification to the HMI (allocatedModules=[], freeModules=[x,y,z])
-- 2) send OnRCStatus notifications to the already registered RC apps (allowed=true, allocatedModules=[], freeModules=[x,y,z])
-- 3) not send OnRCStatus notifications to the already registered non-RC apps
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
  common.wait(2000)
end

local function registerRCAppRCDisallowed()
  local pModuleStatusForApp = {
    freeModules = {},
    allocatedModules = {},
    allowed = false
  }

  common.registerAppWOPTU(1)
  common.validateOnRCStatusForApp(1, pModuleStatusForApp, false)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

local function enableRCFromHMI()
  common.getHMIConnection():SendNotification("RC.OnRemoteControlSettings", { allowed = true })
  common.validateOnRCStatus({ 1 })
  common.getMobileSession(2):ExpectNotification("OnRCStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RC functionality is disallowed from HMI", disableRCFromHMI)
runner.Step("RC app registration", registerRCAppRCDisallowed)
runner.Step("Non-RC app1 registration", common.registerNonRCApp, { 2 })

runner.Title("Test")
runner.Step("RC functionality is allowed from HMI", enableRCFromHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
