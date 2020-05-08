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
-- 2) App allocates module
-- 3) DRIVER_DISTRACTION_VIOLATION is performed from HMI
-- SDL must:
-- 1) Send OnRCStatus notifications to RC app and to HMI by app deallocates module by performing DRIVER_DISTRACTION_VIOLATION form HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function alocateModule(pModuleType)
  common.setModuleStatus(pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.validateOnRCStatus()
end

local function driverDistractionViolation()
  common.driverDistractionViolation()
  common.validateOnRCStatus()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register RC application", common.registerRCApplication)
runner.Step("Activate App", common.activateApp)
runner.Step("App allocates module CLIMATE" , alocateModule, { "CLIMATE" })

runner.Title("Test")
runner.Step("OnRCStatus notification by DRIVER_DISTRACTION_VIOLATION", driverDistractionViolation)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
