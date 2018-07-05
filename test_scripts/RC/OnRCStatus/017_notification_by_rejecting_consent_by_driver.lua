---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall not send OnRCStatus notifications to rc registered app and to HMI
-- in case HMI sends REJECTED resultCode to RC.GetInteriorVehicleDataConsent
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
local function consentRejecting()
  common.rpcRejectWithConsent("CLIMATE", 2, "SetInteriorVehicleData")
  common.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  common.getMobileSession(2):ExpectNotification("OnRCStatus")
  :Times(0)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

local function alocateModule(pModuleType)
  local pModuleStatusAllocatedApp, pModuleStatusAnotherApp = common.setModuleStatus(common.getAllModules(), allocatedModules, pModuleType)
  common.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  common.validateOnRCStatusForApp(1, pModuleStatusAllocatedApp)
  common.validateOnRCStatusForApp(2, pModuleStatusAnotherApp)
  common.validateOnRCStatusForHMI(2, { pModuleStatusAllocatedApp, pModuleStatusAnotherApp }, 1)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Set AccessMode ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Register RC application 1", common.registerRCApplication, { 1 })
runner.Step("Activate App 1", common.activateApp, { 1 })
runner.Step("Register RC application 2", common.registerRCApplication, { 2 })
runner.Step("Activate App 2", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("Allocation of module by App 1", alocateModule, { "CLIMATE" })
runner.Step("Allocation of module by App 2 and rejecting consent by driver", consentRejecting)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
