---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC app is registered
-- 2) Module_1 is allocated by app
-- 3) App tries allocate already allocated module_1
-- SDL must:
-- 1) Not send OnRCStatus notifications to RC app and HMI by second allocation attempt
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function alocateModuleWithoutNot(pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

local function alocateModule(pModuleType)
  common.setModuleStatus(pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.validateOnRCStatus()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application", common.registerRCApplication)
runner.Step("Activate App", common.activateApp)
runner.Step("Allocate module CLIMATE", alocateModule, { "CLIMATE" })

runner.Title("Test")
runner.Step("App allocates module CLIMATE one more time", alocateModuleWithoutNot, { "CLIMATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
