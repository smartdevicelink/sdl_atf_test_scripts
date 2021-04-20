---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) HMI access mode is AUTO_DENY
-- 2) RC app1 and RC app2 are regisered
-- 3) App1 allocates module_1
-- 4) App2 tries allocate the module_1
-- SDL must:
-- 1) Respond with IN_USE result code to app2
-- 2) Not send OnRCStatus notifications to RC registered apps and to HMI
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
  common.validateOnRCStatus({ 1, 2 })
end

local function allocateModuleFromSecondApp(pModuleType)
  local cid = common.getMobileSession(2):SendRPC("SetInteriorVehicleData",
    { moduleData = common.getSettableModuleControlData(pModuleType) })
  EXPECT_HMICALL("RC.SetInteriorVehicleData")
  :Times(0)
  common.getMobileSession(2):ExpectResponse(cid, { success = false, resultCode = "IN_USE" })
  common.getMobileSession(2):ExpectNotification("OnRCStatus")
  :Times(0)
  common.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Set AccessMode AUTO_DENY", common.defineRAMode, { true, "AUTO_DENY" })
runner.Step("Register RC application 1", common.registerRCApplication, { 1 })
runner.Step("Register RC application 2", common.registerRCApplication, { 2 })
runner.Step("Activate App 1", common.activateApp, { 1 })

runner.Title("Test")
runner.Step("Allocation of module by App 1", alocateModule, { "CLIMATE" })
runner.Step("Activate App 2", common.activateApp, { 2 })
runner.Step("Rejected allocation of module by App2", allocateModuleFromSecondApp, { "CLIMATE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
