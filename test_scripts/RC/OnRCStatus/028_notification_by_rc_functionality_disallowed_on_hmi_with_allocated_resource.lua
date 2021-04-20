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
-- 2) RC app is registered
-- 3) RC app allocates module via SetInteriorVehicleData
-- 4) RC functionality is disallowed on HMI
-- SDL must:
-- 1) SDL sends an OnRCStatus notification to the HMI (allocatedModules=[], freeModules=[x,y,z], due to resource freed)
-- 2) SDL sends OnRCStatus notifications to the already registered RC apps (allowed=false, allocatedModules=[], freeModules=[])
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Functions ]]
local function disableRCFromHMI()
  common.disableRCFromHMI()
  common.getMobileSession():ExpectNotification("OnRCStatus",
  { allowed = false, freeModules = {}, allocatedModules = {} })
  local pModuleStatusHMI = {
    freeModules = common.getModulesAllocationByApp(1).freeModules,
    allocatedModules = { }
  }
  common.validateOnRCStatusForHMI(1, pModuleStatusHMI)
end

local function setVehicleData(pModuleType)
  common.setModuleStatus(pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.validateOnRCStatus()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RC app registration", common.registerRCApplication)
runner.Step("Activate App", common.activateApp)
runner.Step("SetInteriorVehicleData RADIO", setVehicleData, { "RADIO" })

runner.Title("Test")
runner.Step("RC functionality is disallowed from HMI", disableRCFromHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
