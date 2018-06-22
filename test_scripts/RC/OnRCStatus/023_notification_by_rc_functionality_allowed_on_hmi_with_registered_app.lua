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
-- 2) RC application is registered
-- 3) RC functionality is allowed on HMI
-- SDL must:
-- 1) Send OnRCStatus notification with allowed = true to registered mobile application and
-- not send to the HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')
local commonRC = require('test_scripts/RC/commonRC')
local test = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function disableRCFromHMI()
  common.getHMIconnection():SendNotification("RC.OnRemoteControlSettings", { allowed = false })
  common.wait(2000)
end

local function registerRCAppRCDisallowed()
  local pModuleStatusForApp = {
    freeModules = {},
    allocatedModules = { },
    allowed = false
  }

  commonRC.rai_n(1, test)
  common.validateOnRCStatusForApp(1, pModuleStatusForApp, true)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

local function enableRCFromHMI()
  local pModuleStatus = {
  freeModules = common.getModulesArray(common.getAllModules()),
    allocatedModules = { },
    allowed = true
  }
  common.getHMIconnection():SendNotification("RC.OnRemoteControlSettings", { allowed = true })
  common.validateOnRCStatusForApp(1, pModuleStatus, true)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RC functionality is disallowed from HMI", disableRCFromHMI)
runner.Step("RC app registration", registerRCAppRCDisallowed)

runner.Title("Test")
runner.Step("RC functionality is allowed from HMI", enableRCFromHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
